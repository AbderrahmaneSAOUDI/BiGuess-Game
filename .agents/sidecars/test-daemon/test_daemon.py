#!/usr/bin/env python3
"""Run Flutter tests once, or explicitly watch relevant files without overlap."""
from __future__ import annotations

import argparse
import fcntl
import os
from pathlib import Path
import signal
import subprocess
import sys
import threading
import time


def snapshot(root: Path) -> tuple[tuple[str, int, int], ...]:
    files = [root / 'pubspec.yaml', root / 'pubspec.lock', root / 'analysis_options.yaml']
    for name in ('lib', 'test'):
        directory = root / name
        if directory.is_symlink():
            continue
        for current, dirs, names in os.walk(directory, followlinks=False):
            dirs[:] = sorted(name for name in dirs if not name.startswith('.')
                             and not (Path(current) / name).is_symlink())
            files.extend(Path(current) / name for name in names if name.endswith('.dart'))
    entries = []
    for path in sorted(files):
        try:
            if not path.is_symlink():
                metadata = path.stat()
                entries.append((path.relative_to(root).as_posix(),
                                metadata.st_mtime_ns, metadata.st_size))
        except FileNotFoundError:
            continue
    return tuple(entries)


def run_tests(root: Path, targets: list[str], timeout: float,
              stopped: threading.Event) -> int:
    process = subprocess.Popen(['flutter', 'test', *targets], cwd=root, start_new_session=True)
    deadline = time.monotonic() + timeout
    while process.poll() is None:
        if stopped.wait(0.2) or time.monotonic() >= deadline:
            try:
                os.killpg(process.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
            return 130 if stopped.is_set() else 124
    return process.returncode


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--once', action='store_true', help='run once (default)')
    mode.add_argument('--watch', action='store_true', help='watch in the foreground')
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[3])
    parser.add_argument('--interval', type=float, default=3)
    parser.add_argument('--timeout', type=float, default=300, help='seconds per test run')
    parser.add_argument('targets', nargs='*', help='optional test files/directories')
    args = parser.parse_args()
    if args.interval < 1 or args.timeout < 1:
        parser.error('--interval and --timeout must be at least 1 second')
    root = args.root.resolve()
    if not (root / 'pubspec.yaml').is_file():
        parser.error('--root must contain pubspec.yaml')
    cache = root / '.agents' / 'cache'
    cache.mkdir(parents=True, exist_ok=True)
    stopped = threading.Event()
    for event in (signal.SIGINT, signal.SIGTERM):
        signal.signal(event, lambda *_: stopped.set())
    with (cache / 'test-watcher.lock').open('a') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print('A test sidecar is already running for this project.', file=sys.stderr)
            return 1
        previous = None
        result = 0
        while not stopped.is_set():
            current = snapshot(root)
            if current != previous:
                try:
                    result = run_tests(root, args.targets, args.timeout, stopped)
                except FileNotFoundError:
                    print('flutter is unavailable on PATH.', file=sys.stderr)
                    return 127
                previous = current
            if not args.watch:
                return result if result >= 0 else 1
            stopped.wait(args.interval)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
