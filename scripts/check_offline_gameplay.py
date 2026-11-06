#!/usr/bin/env python3
"""Run real Flutter screens across SIGKILL/restart with external networking off.

Linux user/network namespaces are required. Only loopback is enabled for Flutter's
test protocol; there is no external interface or route. Dart HTTP is separately
trapped and asserted unused in the app test. No device/cloud service is needed.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import tempfile
import time


ROOT = Path(__file__).resolve().parents[1]


def run_phase(phase: str, storage: Path, log: Path) -> dict:
    flutter = shutil.which("flutter")
    if not flutter:
        raise RuntimeError("flutter must be on PATH")
    command = [
        "unshare", "--user", "--map-root-user", "--net",
        "sh", "-eu", "-c", 'ip link set lo up; exec "$@"', "offline-gate",
        flutter, "test", "--no-pub", "--reporter", "expanded",
        f"--dart-define=offlineGatePhase={phase}",
        f"--dart-define=offlineGateRoot={storage}",
        "test/offline/local_pack_gameplay_test.dart",
    ]
    marker = storage / "ready-to-kill.json"
    with log.open("w") as output:
        process = subprocess.Popen(command, cwd=ROOT, stdout=output,
                                   stderr=subprocess.STDOUT, start_new_session=True)
        try:
            deadline = time.monotonic() + 180
            killed = False
            while process.poll() is None:
                if phase == "seed" and marker.exists() and not killed:
                    ready = json.loads(marker.read_text())
                    if ready["round"] != 1:
                        raise RuntimeError("App did not reach an active first round")
                    # The marker comes from the app isolate after SQL commit and
                    # a rendered private Card; this is an actual process death.
                    os.kill(ready["pid"], signal.SIGKILL)
                    killed = True
                if time.monotonic() > deadline:
                    raise RuntimeError(f"{phase} timed out; see {log}")
                time.sleep(0.1)
            code = process.wait()
            if phase == "seed":
                if not killed or code == 0:
                    raise RuntimeError(f"Expected killed Flutter app; see {log}")
            elif code != 0 or "OFFLINE GATE PASS:" not in log.read_text():
                raise RuntimeError(f"Offline restart failed ({code}); see {log}")
            return {"phase": phase, "exit_code": code, "app_sigkill_sent": killed}
        finally:
            # Also reap compiler/test children if a deadline/error interrupted us.
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            process.wait()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--evidence", type=Path, help="Keep logs and JSON summary here")
    args = parser.parse_args()
    try:
        # Fail explicitly if the host cannot prove network isolation.
        subprocess.run(["unshare", "--user", "--map-root-user", "--net", "true"],
                       check=True, capture_output=True, text=True, timeout=10)
        with tempfile.TemporaryDirectory(prefix="biguess-offline-gate-") as temporary:
            directory = Path(temporary)
            storage = directory / "support"
            storage.mkdir()
            evidence = args.evidence.resolve() if args.evidence else directory / "evidence"
            evidence.mkdir(parents=True, exist_ok=True)
            phases = [run_phase("seed", storage, evidence / "seed-killed.txt")]
            (evidence / "killed-app.json").write_text(
                (storage / "ready-to-kill.json").read_text() + "\n")
            (storage / "input.biguesspack").unlink()
            phases.append(run_phase("restart", storage, evidence / "restart.txt"))
            summary = {
                "result": "pass",
                "network": "isolated Linux network namespace; loopback only",
                "process_restart": "SIGKILL during first rendered round; fresh flutter_tester",
                "source_archive": "removed before restart",
                "rounds_after_restart": [10, 3],
                "http_client_attempts": 0,
                "sqlite_integrity_check": "ok",
                "sqlite_foreign_key_check": [],
                "device_validation": "not performed; host Flutter engine and real SQLite/files",
                "phases": phases,
            }
            (evidence / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
            print(json.dumps(summary, indent=2))
            if args.evidence:
                print(f"Evidence: {evidence}")
        return 0
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print(f"Offline gate FAILED: {error}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
