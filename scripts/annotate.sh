#!/bin/sh
# Prints the compiler errors and the failed assertions of a build log as annotations of the run, ten at
# a time (a step can only have ten of them). Usage: annotate.sh <log> [offset]

log="$1"
offset="${2:-0}"

[ -f "$log" ] || exit 0

grep -E '^.+\.swift:[0-9]+(:[0-9]+)?: error: ' "$log" | sort -u | sed -n "$((offset + 1)),$((offset + 10))p" | while IFS= read -r line; do
  file=$(printf '%s' "$line" | sed -E 's/^(.+\.swift):[0-9]+.*/\1/')
  number=$(printf '%s' "$line" | sed -E 's/^.+\.swift:([0-9]+).*/\1/')
  message=$(printf '%s' "$line" | sed -E 's/^.+\.swift:[0-9]+(:[0-9]+)?: error: //' | sed -e 's/%/%25/g')
  file="${file#"$GITHUB_WORKSPACE"/}"
  echo "::error file=$file,line=$number::$message"
done
