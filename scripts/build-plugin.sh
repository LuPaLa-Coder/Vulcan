#!/usr/bin/env bash
# =============================================================================
#  Vulcan — Build del plugin Claude Code
#
#  Genera plugin/agents/*.md dai file sorgente root (Vulcan.*.agent.md), che
#  restano l'unica fonte di verità anche per install.sh. Il frontmatter segue
#  la variante "claude" di install.sh: name, description, version e, solo per
#  Dispatch e SCA, la lista tools.
#
#  Uso:  ./scripts/build-plugin.sh
#  Da rieseguire dopo ogni modifica a Vulcan.*.agent.md.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
AGENTS_DIR="$ROOT/plugin/agents"

RED='\033[0;31m' GREEN='\033[0;32m' NC='\033[0m'

SRC_FILE=(
    "Vulcan.Dispatch.agent.md"
    "Vulcan.Core.agent.md"
    "Vulcan.Patterns.agent.md"
    "Vulcan.AWS.agent.md"
    "Vulcan.Azure.agent.md"
    "Vulcan.SCA.agent.md"
)
DEST_FILE=(
    "vulcan-dispatch.md"
    "vulcan-core.md"
    "vulcan-patterns.md"
    "vulcan-aws.md"
    "vulcan-azure.md"
    "vulcan-sca.md"
)
# Tools Claude Code per agente (vuoto = ereditati dall'host).
TOOLS=(
    "Read, Grep, Glob, Agent"
    ""
    ""
    ""
    ""
    "Read, Grep, Glob, Bash, Agent"
)

mkdir -p "$AGENTS_DIR"
rm -f "$AGENTS_DIR"/*.md

frontmatter_field() {
    awk -v field="$2" '
      BEGIN { c = 0 }
      /^---$/ { c++; if (c >= 2) exit; next }
      c == 1 {
        pattern = "^" field ":[ ]*"
        if ($0 ~ pattern) { sub(pattern, ""); gsub(/^"|"$/, ""); print; exit }
      }
    ' "$1"
}

body_of() {
    tr -d '\r' < "$1" | awk '
      BEGIN { c = 0 }
      /^---$/ && c < 2 { c++; next }
      c >= 2 { print }
    '
}

build_agent() {
    local src="$ROOT/$1" dest="$AGENTS_DIR/$2" tools="$3"
    local name description version
    name=$(frontmatter_field "$src" "name")
    description=$(frontmatter_field "$src" "description")
    version=$(frontmatter_field "$src" "version")

    if [[ -z "$name" || -z "$description" ]]; then
        echo -e "${RED}✗${NC} frontmatter incompleto in $src" >&2
        return 1
    fi

    {
        echo "---"
        echo "name: ${name}"
        echo "description: \"${description}\""
        [[ -n "$version" ]] && echo "version: \"${version}\""
        [[ -n "$tools" ]] && echo "tools: ${tools}"
        echo "---"
        echo ""
        echo "<!-- File generato da scripts/build-plugin.sh — non modificare a mano."
        echo "     Sorgente: $1 (root). -->"
        body_of "$src"
    } > "$dest"
    echo -e "  ${GREEN}✓${NC} plugin/agents/$2 <- $1"
}

echo "Generazione agent plugin da sorgenti root..."
for i in "${!SRC_FILE[@]}"; do
    build_agent "${SRC_FILE[$i]}" "${DEST_FILE[$i]}" "${TOOLS[$i]}"
done
echo -e "${GREEN}✓${NC} Plugin generato in plugin/."
