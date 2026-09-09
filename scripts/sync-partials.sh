#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

for target in Vulcan.*.agent.md; do
  for partial_path in partials/*.md; do
    name=$(basename "$partial_path" .md)
    marker_begin="<!-- BEGIN:PARTIAL:${name} -->"
    marker_end="<!-- END:PARTIAL:${name} -->"

    grep -qF "$marker_begin" "$target" || continue

    target_lines_before=$(wc -l < "$target")

    awk -v begin="$marker_begin" -v end="$marker_end" -v partial="$partial_path" '
      BEGIN { in_block = 0; while ((getline line < partial) > 0) content = content line "\n" }
      $0 == begin { print; printf "%s", content; in_block = 1; next }
      $0 == end { in_block = 0 }
      !in_block { print }
    ' "$target" > "${target}.tmp"

    # Guardia anti-corruzione: se il marker BEGIN non ha un END corrispondente
    # (typo, modifica manuale) o il partial è vuoto/illeggibile, l'output può
    # perdere silenziosamente tutto il contenuto successivo al BEGIN. Un output
    # vuoto o con meno della metà delle righe originali è un segnale chiaro
    # che qualcosa è andato storto: abortiamo senza toccare il target.
    tmp_lines=$(wc -l < "${target}.tmp" 2>/dev/null || echo 0)
    if [[ ! -s "${target}.tmp" ]]; then
      echo "sync-partials: ERRORE — output vuoto generato per '$target' (partial '$name'). File originale lasciato invariato." >&2
      rm -f "${target}.tmp"
      exit 1
    fi
    if (( tmp_lines * 2 < target_lines_before )); then
      echo "sync-partials: ERRORE — output sospetto per '$target' (partial '$name'): $tmp_lines righe contro $target_lines_before originali (probabile marker BEGIN senza END corrispondente, o partial vuoto). File originale lasciato invariato." >&2
      rm -f "${target}.tmp"
      exit 1
    fi

    # Nota: `cat > target` (non `mv`) per riscrivere in place e preservare
    # i permessi originali del file target — `mv` sostituirebbe l'inode
    # con quello del temp file (permessi di default da umask), rompendo
    # l'idempotenza quando il target ha un mode non standard (es. 755).
    cat "${target}.tmp" > "$target"
    rm -f "${target}.tmp"
  done
done

echo "sync-partials: completato su $(ls Vulcan.*.agent.md | wc -l | tr -d ' ') file"
