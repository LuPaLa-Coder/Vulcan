#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

for target in Vulcan.*.agent.md; do
  for partial_path in partials/*.md; do
    name=$(basename "$partial_path" .md)
    marker_begin="<!-- BEGIN:PARTIAL:${name} -->"
    marker_end="<!-- END:PARTIAL:${name} -->"

    grep -qF "$marker_begin" "$target" || continue

    awk -v begin="$marker_begin" -v end="$marker_end" -v partial="$partial_path" '
      BEGIN { in_block = 0; while ((getline line < partial) > 0) content = content line "\n" }
      $0 == begin { print; printf "%s", content; in_block = 1; next }
      $0 == end { in_block = 0 }
      !in_block { print }
    ' "$target" > "${target}.tmp"
    mv "${target}.tmp" "$target"
  done
done

echo "sync-partials: completato su $(ls Vulcan.*.agent.md | wc -l | tr -d ' ') file"
