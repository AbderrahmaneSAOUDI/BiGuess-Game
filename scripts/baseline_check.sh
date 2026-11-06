#!/usr/bin/env bash
# Capture every baseline gate even if an earlier gate fails. Never publish or
# repair release metadata. Use --fast to omit platform diagnostics/debug build.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [[ ${1:-} == --help || ${1:-} == -h ]]; then
  echo "Usage: bash scripts/baseline_check.sh [--fast] [output-directory]"
  echo "Run every verification gate and save logs. --fast skips SDK diagnostics and the Android debug build."
  exit 0
fi

mode=full
if [[ ${1:-} == --fast ]]; then
  mode=fast
  shift
fi
if [[ $# -gt 1 || ${1:-} == -* ]]; then
  echo "Usage: bash scripts/baseline_check.sh [--fast] [output-directory]" >&2
  exit 2
fi
output=${1:-".agents/cache/baseline/$(date -u +%Y%m%dT%H%M%SZ)"}
mkdir -p "$output"
summary="$output/summary.tsv"
printf 'check\texit_code\n' > "$summary"
{
  git rev-parse HEAD || true
  git status --short || true
  date -u +%Y-%m-%dT%H:%M:%SZ
  flutter --version || true
  python3 --version || true
  python3 -c 'import PIL; print("Pillow", PIL.__version__)' || true
} > "$output/context.txt" 2>&1
failed=0
run_check() {
  local name=$1 code=0
  shift
  echo "Running $name (log: $output/$name.txt)"
  "$@" > "$output/$name.txt" 2>&1 || code=$?
  printf '%s\t%s\n' "$name" "$code" >> "$summary"
  if [[ $code -ne 0 ]]; then
    failed=1
    tail -n 15 "$output/$name.txt"
  fi
}

run_check dependencies flutter pub get
run_check format dart format --output=none --set-exit-if-changed lib test
run_check analyze flutter analyze --fatal-infos
run_check tests flutter test --reporter expanded
run_check manifest python3 scripts/generate_manifest.py --check
run_check assets python3 scripts/audit_assets.py
run_check versions python3 .agents/hooks/project_check.py --check
run_check tooling_syntax python3 -m compileall -q scripts .agents/hooks
run_check agent_tests python3 -m unittest discover -s .agents/tests -v
run_check failure_detection python3 scripts/check_ci_failure_detection.py
if [[ -f .agents/scripts/validate_setup.py ]]; then
  run_check agent_setup python3 .agents/scripts/validate_setup.py
fi
if [[ $mode == full ]]; then
  run_check statistics python3 scripts/character_stats.py
  run_check doctor flutter doctor -v
  run_check debug_build flutter build apk --debug
fi
cat "$summary"
exit "$failed"
