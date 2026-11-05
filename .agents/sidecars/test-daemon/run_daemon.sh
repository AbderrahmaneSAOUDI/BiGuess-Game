#!/usr/bin/env bash
# Universal Test Daemon Runner
# Detects project test command and runs tests in watch mode if supported.

if [ -f "package.json" ]; then
  npm test -- --watch
elif [ -f "pubspec.yaml" ]; then
  flutter test
elif [ -f "pyproject.toml" ] || [ -f "pytest.ini" ]; then
  pytest -f
elif [ -f "Cargo.toml" ]; then
  cargo test
else
  echo "No recognized test runner found."
fi
