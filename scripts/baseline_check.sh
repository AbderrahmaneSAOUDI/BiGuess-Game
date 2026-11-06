#!/usr/bin/env bash
# Capture every baseline gate even if an earlier gate fails. Never publish or
# repair release metadata. Use --fast to omit platform diagnostics/debug build.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

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
  git rev-parse HEAD
  git status --short
  date -u +%Y-%m-%dT%H:%M:%SZ
  flutter --version
  python3 --version
  python3 -c 'import PIL; print("Pillow", PIL.__version__)'
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
run_check agent_setup python3 .agents/scripts/validate_setup.py
run_check agent_tests python3 -m unittest discover -s .agents/tests -v
if [[ $mode == full ]]; then
  run_check statistics python3 scripts/character_stats.py
  run_check doctor flutter doctor -v
  run_check debug_build flutter build apk --debug
fi
cat "$summary"
exit "$failed"
