#!/usr/bin/env python3
"""Prove the CI analyzer/test commands reject temporary defects, then remove them."""
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def check_failure(folder, suffix, source, command, expected_message):
    with tempfile.NamedTemporaryFile(
        mode="w", encoding="utf-8", dir=ROOT / folder,
        prefix="ci_negative_", suffix=suffix, delete=False,
    ) as fixture:
        fixture.write(source)
        path = Path(fixture.name)
    try:
        command = [*command, *([str(path.relative_to(ROOT))] if folder == "test" else [])]
        result = subprocess.run(command, cwd=ROOT, text=True, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, timeout=180)
        print("Command:", " ".join(command), flush=True)
        print(result.stdout, flush=True)
        if result.returncode != 1 or expected_message not in result.stdout:
            raise RuntimeError(f"Expected diagnostic {expected_message!r} and exit 1; got {result.returncode}")
        print(f"PASS: expected exit 1 and {expected_message!r} detected", flush=True)
    finally:
        path.unlink()


def main():
    check_failure("lib", ".dart", "final int deliberateCiTypeError = 'wrong type';\n",
                  ["flutter", "analyze", "--fatal-infos"], "invalid_assignment")
    check_failure("test", "_test.dart",
                  "import 'package:flutter_test/flutter_test.dart';\n"
                  "void main() { test('deliberate CI failure', () { expect(1 + 1, 3); }); }\n",
                  ["flutter", "test", "--reporter", "expanded"], "Expected: <3>")


if __name__ == "__main__":
    main()
