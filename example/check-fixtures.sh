#!/usr/bin/env bash
# Runs the codemod on every fixtures/<case>/input.* and diffs it with expected.*
# Usage: check-fixtures.sh [project-dir]  (project-dir holds sgconfig.yml and fixtures/)
set -euo pipefail

project_dir="$(cd "${1:-.}" && pwd)"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

cp -R "$project_dir/fixtures/." "$work_dir/"
find "$work_dir" -name 'expected.*' -delete
# ast-grep rewrites in place; scanning a copy keeps the fixtures untouched.
ast-grep scan --config "$project_dir/sgconfig.yml" --update-all "$work_dir" >/dev/null </dev/null

failures=0
for input in "$work_dir"/*/input.*; do
  case_name="$(basename "$(dirname "$input")")"
  expected="$project_dir/fixtures/$case_name/expected.${input##*.}"
  if diff -u --label "expected" --label "actual" "$expected" "$input"; then
    echo "PASS $case_name"
  else
    echo "FAIL $case_name"
    failures=$((failures + 1))
  fi
done

exit "$failures"
