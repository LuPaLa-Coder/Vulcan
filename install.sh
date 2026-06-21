#!/usr/bin/env bash
# =============================================================================
#  Vulcan C# Agent — Global Installer
#  Installa Vulcan per tutti i coding agent rilevati con frontmatter nativo:
#  Claude Code · OpenCode · GitHub Copilot · Cursor · Windsurf · Codex
#
#  Uso:
#    curl -fsSL https://raw.githubusercontent.com/PaoEng/Vulcan/main/install.sh | bash
#    ./install.sh                    # installa in tutti gli agent rilevati
#    ./install.sh --local            # installa solo nella directory corrente
#    ./install.sh --agent claude     # installa solo per Claude Code
#    ./install.sh --agent opencode   # installa solo per OpenCode
#    ./install.sh --agent copilot    # installa solo per GitHub Copilot
#    ./install.sh --agent cursor     # installa solo per Cursor
#    ./install.sh --agent windsurf   # installa solo per Windsurf
#    ./install.sh --agent codex      # installa solo per Codex
#    ./install.sh --backup            # installa con backup dei file esistenti
#    ./install.sh --uninstall        # rimuove Vulcan da tutti gli agent
# =============================================================================

set -euo pipefail

# ── Colori ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'   GREEN='\033[0;32m'   YELLOW='\033[1;33m'
CYAN='\033[0;36m'  BOLD='\033[1m'      NC='\033[0m'

# ── Configurazione ───────────────────────────────────────────────────────────
VULCAN_VERSION="1.2.0"
AGENT_FILE="Vulcan.agent.md"
REPO_URL="https://raw.githubusercontent.com/PaoEng/Vulcan/main"
AGENT_DESC="Vulcan C# Agent — sviluppo C# moderno (.NET 10 LTS / .NET 8 LTS), cloud-native (AWS/Azure) e provider-agnostic con Serilog + OpenTelemetry, LiteDB/MongoDB, supply-chain hardened e pattern architetturali puliti. Usare per GENERARE codice C#; per CODE REVIEW usare Anubis."

# ── Banner ───────────────────────────────────────────────────────────────────
print_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "  ⚡ Vulcan C# Agent — Global Installer v${VULCAN_VERSION}"
    echo -e "${NC}"
    echo "  C# .NET 10/8 · AWS · Azure · Generic — Cloud-Native Development Agent"
    echo ""
}

# ── OS Detection ─────────────────────────────────────────────────────────────
detect_os() {
    case "$(uname -s)" in
        Darwin*)  OS="macos" ;;
        Linux*)   OS="linux" ;;
        MINGW*|MSYS*|CYGWIN*) OS="windows" ;;
        *)        OS="unknown" ;;
    esac
}

# ── Agent Body ──────────────────────────────────────────────────────────────
# Estrae il corpo dell'agente (tutto dopo il frontmatter YAML) dal file sorgente.
# Prova prima locale, poi scarica da GitHub.

get_agent_body() {
    local src=""

    if [[ -f "$SCRIPT_DIR/$AGENT_FILE" ]]; then
        src="$SCRIPT_DIR/$AGENT_FILE"
    else
        src=$(mktemp)
        if command -v curl &>/dev/null; then
            curl -fsSL "${REPO_URL}/${AGENT_FILE}" -o "$src" || {
                rm -f "$src"
                echo -e "${RED}✗${NC} Download fallito da ${REPO_URL}/${AGENT_FILE}" >&2
                return 1
            }
        elif command -v wget &>/dev/null; then
            wget -q "${REPO_URL}/${AGENT_FILE}" -O "$src" || {
                rm -f "$src"
                echo -e "${RED}✗${NC} Download fallito da ${REPO_URL}/${AGENT_FILE}" >&2
                return 1
            }
        else
            echo -e "${RED}✗${NC} Nessuno tra curl o wget disponibile. Installa curl e riprova." >&2
            return 1
        fi
    fi

    # Estrai il corpo: salta tutto fino al secondo --- (fine frontmatter YAML)
    awk 'BEGIN { c=0 } /^---$/ { c++; next } c >= 2' "$src"

    # Pulizia se è stato scaricato in tmp
    if [[ "$src" != "$SCRIPT_DIR/$AGENT_FILE" ]]; then
        rm -f "$src"
    fi
}

# ── Frontmatter per piattaforma ──────────────────────────────────────────────
# Ogni coding agent ha un formato frontmatter diverso.
# Claude Code: name + description, tools ereditati dall'host
# OpenCode:    description + mode + permission (oggetto con allow/deny per tool)
# Generico:    name + description (Copilot, Cursor, Windsurf, Codex)

get_frontmatter() {
    local platform="$1"  # claude | opencode | generic

    case "$platform" in
        claude)
            cat <<'EOF'
---
name: Vulcan
description: "Vulcan C# Agent — sviluppo C# moderno (.NET 10 LTS / .NET 8 LTS), cloud-native (AWS/Azure) e provider-agnostic con Serilog + OpenTelemetry, LiteDB/MongoDB, supply-chain hardened e pattern architetturali puliti. Usare per GENERARE codice C#; per CODE REVIEW usare Anubis."
---
EOF
            ;;
        opencode)
            cat <<'EOF'
---
description: "Vulcan C# Agent — sviluppo C# moderno (.NET 10 LTS / .NET 8 LTS), cloud-native (AWS/Azure) e provider-agnostic con Serilog + OpenTelemetry, LiteDB/MongoDB, supply-chain hardened e pattern architetturali puliti. Usare per GENERARE codice C#; per CODE REVIEW usare Anubis."
mode: all
permission:
  read: allow
  glob: allow
  grep: allow
  edit: allow
  write: allow
  bash: allow
  webfetch: allow
  websearch: allow
  task: allow
---
EOF
            ;;
        generic)
            cat <<'EOF'
---
name: Vulcan
description: "Vulcan C# Agent — sviluppo C# moderno (.NET 10 LTS / .NET 8 LTS), cloud-native (AWS/Azure) e provider-agnostic con Serilog + OpenTelemetry, LiteDB/MongoDB, supply-chain hardened e pattern architetturali puliti. Usare per GENERARE codice C#; per CODE REVIEW usare Anubis."
---
EOF
            ;;
    esac
}

# Mappa il nome dell'agente al tipo di piattaforma per il frontmatter
get_platform() {
    case "$1" in
        "OpenCode"|"OpenCode (XDG)") echo "opencode" ;;
        "Claude Code")               echo "claude" ;;
        *)                           echo "generic" ;;
    esac
}

# ── Agent Directories ────────────────────────────────────────────────────────
# Ogni coding agent ha una directory specifica dove cerca i file .md degli agenti.
# La funzione stampa ogni entry come "path|nome" su una riga separata.

get_agent_dirs() {
    local agent="$1"  # vuoto = tutti, oppure nome specifico
    local xdg_config="${XDG_CONFIG_HOME:-$HOME/.config}"

    case "$OS" in
        macos|linux)
            # Claude Code — ~/.claude/agents/
            if [[ -z "$agent" || "$agent" == "claude" ]]; then
                if command -v claude &>/dev/null || [[ -d "$HOME/.claude" ]]; then
                    printf '%s|%s\n' "$HOME/.claude/agents" "Claude Code"
                fi
            fi

            # OpenCode — ~/.opencode/agents/ e XDG
            if [[ -z "$agent" || "$agent" == "opencode" ]]; then
                if [[ -d "$HOME/.opencode" ]]; then
                    printf '%s|%s\n' "$HOME/.opencode/agents" "OpenCode"
                fi
                if [[ -d "$xdg_config/opencode/agents" ]]; then
                    printf '%s|%s\n' "$xdg_config/opencode/agents" "OpenCode (XDG)"
                fi
            fi

            # GitHub Copilot — ~/.copilot/agents/
            if [[ -z "$agent" || "$agent" == "copilot" ]]; then
                if [[ -d "$HOME/.copilot" ]] || [[ -d "$HOME/.vscode" ]] || command -v code &>/dev/null; then
                    printf '%s|%s\n' "$HOME/.copilot/agents" "GitHub Copilot"
                fi
            fi

            # Cursor — ~/.cursor/agents/
            if [[ -z "$agent" || "$agent" == "cursor" ]]; then
                if [[ -d "$HOME/.cursor" ]] || [[ -d "/Applications/Cursor.app" ]] || command -v cursor &>/dev/null; then
                    printf '%s|%s\n' "$HOME/.cursor/agents" "Cursor"
                fi
            fi

            # Windsurf — ~/.windsurf/agents/
            if [[ -z "$agent" || "$agent" == "windsurf" ]]; then
                if [[ -d "$HOME/.windsurf" ]] || [[ -d "/Applications/Windsurf.app" ]]; then
                    printf '%s|%s\n' "$HOME/.windsurf/agents" "Windsurf"
                fi
            fi

            # Codex — ~/.codex/agents/
            if [[ -z "$agent" || "$agent" == "codex" ]]; then
                if [[ -d "$HOME/.codex" ]] || command -v codex &>/dev/null; then
                    printf '%s|%s\n' "$HOME/.codex/agents" "OpenAI Codex"
                fi
            fi
            ;;

        windows)
            local appdata="${APPDATA:-$HOME/AppData/Roaming}"

            if [[ -z "$agent" || "$agent" == "claude" ]]; then
                printf '%s|%s\n' "$appdata/Claude/agents" "Claude Code"
            fi
            if [[ -z "$agent" || "$agent" == "opencode" ]]; then
                printf '%s|%s\n' "$HOME/.opencode/agents" "OpenCode"
            fi
            if [[ -z "$agent" || "$agent" == "copilot" ]]; then
                printf '%s|%s\n' "$HOME/.copilot/agents" "GitHub Copilot"
            fi
            if [[ -z "$agent" || "$agent" == "cursor" ]]; then
                printf '%s|%s\n' "$appdata/Cursor/agents" "Cursor"
            fi
            if [[ -z "$agent" || "$agent" == "codex" ]]; then
                printf '%s|%s\n' "$HOME/.codex/agents" "OpenAI Codex"
            fi
            ;;
    esac
}

# ── Installa ─────────────────────────────────────────────────────────────────
install_agent() {
    local target_dir="$1"
    local agent_name="$2"
    local platform
    platform=$(get_platform "$agent_name")

    mkdir -p "$target_dir"
    local dest="${target_dir}/${AGENT_FILE}"

    # Backup solo se richiesto esplicitamente con --backup
    if [[ "$DO_BACKUP" == "true" ]] && [[ -f "$dest" ]]; then
        local backup="${dest}.backup-$(date +%Y%m%d-%H%M%S)"
        cp "$dest" "$backup"
        echo -e "  ${YELLOW}↻${NC} Backup creato: ${backup}"
    fi

    # Genera il file con frontmatter specifico per la piattaforma + corpo
    {
        get_frontmatter "$platform"
        echo ""
        get_agent_body
    } > "$dest"

    if [[ -s "$dest" ]]; then
        echo -e "  ${GREEN}✓${NC} Vulcan installato per ${BOLD}${agent_name}${NC} (${platform})"
        echo -e "          → ${dest}"
        return 0
    else
        echo -e "  ${RED}✗${NC} Generazione fallita per ${agent_name}"
        return 1
    fi
}

# ── Uninstall ────────────────────────────────────────────────────────────────
uninstall_agent() {
    local target_dir="$1"
    local agent_name="$2"
    local dest="${target_dir}/${AGENT_FILE}"

    if [[ -f "$dest" ]]; then
        rm "$dest"
        echo -e "  ${GREEN}✓${NC} Vulcan rimosso da ${BOLD}${agent_name}${NC}"
    else
        echo -e "  ${YELLOW}○${NC} Vulcan non presente per ${agent_name}"
    fi
}

# ── Local Install ────────────────────────────────────────────────────────────
install_local() {
    local local_dir="${1:-$PWD}"
    local dest="${local_dir}/.claude/agents/${AGENT_FILE}"

    mkdir -p "$(dirname "$dest")"

    # Per installazione locale usiamo il frontmatter Claude (più comune)
    {
        get_frontmatter "claude"
        echo ""
        get_agent_body
    } > "$dest"

    if [[ -s "$dest" ]]; then
        echo -e "  ${GREEN}✓${NC} Vulcan installato localmente"
        echo -e "          → ${dest}"
    else
        echo -e "  ${RED}✗${NC} Installazione locale fallita"
        return 1
    fi

    # Crea settings.json Claude Code
    local settings="${local_dir}/.claude/settings.json"
    if [[ ! -f "$settings" ]]; then
        cat > "$settings" <<'SETTINGS'
{
  "agents": {
    "Vulcan": {
      "description": "Vulcan C# Agent — sviluppo C# moderno cloud-native (AWS/Azure/Generic)",
      "path": ".claude/agents/Vulcan.agent.md"
    }
  }
}
SETTINGS
        echo -e "  ${GREEN}✓${NC} Creato .claude/settings.json con registrazione agent"
    fi
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
    print_banner

    detect_os
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    local mode="install"
    local target_agent=""
    DO_BACKUP="false"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --uninstall)
                mode="uninstall"
                shift
                ;;
            --local)
                mode="local"
                shift
                ;;
            --backup)
                DO_BACKUP="true"
                shift
                ;;
            --agent)
                target_agent="${2:-}"
                if [[ -z "$target_agent" ]]; then
                    echo -e "${RED}✗${NC} Specifica un agent: claude, opencode, copilot, cursor, windsurf, codex"
                    exit 1
                fi
                shift 2
                ;;
            --help|-h)
                echo "Uso: $0 [--local] [--agent <name>] [--backup] [--uninstall] [--help]"
                echo ""
                echo "Opzioni:"
                echo "  --local            Installa solo nella directory corrente"
                echo "  --agent <name>     Installa solo per un agent specifico"
                echo "  --backup           Crea backup del file agent esistente prima di sovrascrivere"
                echo "  --uninstall        Rimuove Vulcan da tutti gli agent"
                echo "  --help, -h         Mostra questo help"
                echo ""
                echo "Agent supportati:"
                echo "  claude    — Claude Code"
                echo "  opencode  — OpenCode"
                echo "  copilot   — GitHub Copilot (VS Code / CLI)"
                echo "  cursor    — Cursor"
                echo "  windsurf  — Windsurf"
                echo "  codex     — OpenAI Codex"
                exit 0
                ;;
            *)
                echo -e "${RED}✗${NC} Opzione sconosciuta: $1"
                echo "Usa --help per vedere le opzioni disponibili"
                exit 1
                ;;
        esac
    done

    # ── Modalità: Local ──────────────────────────────────────────────────
    if [[ "$mode" == "local" ]]; then
        echo -e "${BOLD}Installazione locale di Vulcan${NC}"
        echo ""
        install_local
        echo ""
        echo -e "${GREEN}${BOLD}✓${NC} Vulcan installato localmente!"
        echo ""
        echo "  Per usarlo: seleziona 'Vulcan' dal menu agent quando richiesto."
        exit 0
    fi

    # ── Modalità: Uninstall ──────────────────────────────────────────────
    if [[ "$mode" == "uninstall" ]]; then
        echo -e "${BOLD}Disinstallazione di Vulcan${NC}"
        echo ""

        local removed=0
        while IFS='|' read -r dir name; do
            [[ -z "$dir" ]] && continue
            uninstall_agent "$dir" "$name"
            removed=$((removed + 1))
        done < <(get_agent_dirs "$target_agent")

        echo ""
        echo -e "${GREEN}${BOLD}✓${NC} Vulcan disinstallato da ${removed} agent directory."
        exit 0
    fi

    # ── Modalità: Install ────────────────────────────────────────────────
    echo -e "${BOLD}Installazione globale di Vulcan${NC}"
    echo -e "  OS rilevato: ${CYAN}${OS}${NC}"
    echo ""

    # Verifica che possiamo ottenere il corpo dell'agente prima di procedere
    if ! get_agent_body > /dev/null 2>&1; then
        echo -e "${RED}✗${NC} Impossibile accedere al file agente. Verifica la connessione."
        exit 1
    fi

    local installed=0
    local skipped=0

    while IFS='|' read -r dir name; do
        [[ -z "$dir" ]] && continue
        if install_agent "$dir" "$name"; then
            installed=$((installed + 1))
        else
            skipped=$((skipped + 1))
        fi
    done < <(get_agent_dirs "$target_agent")

    echo ""
    echo -e "${GREEN}${BOLD}✓${NC} Completato: ${installed} agent installati, ${skipped} saltati"

    if [[ -z "$target_agent" && $installed -eq 0 ]]; then
        echo ""
        echo -e "${YELLOW}${BOLD}⚠${NC} Nessun coding agent rilevato sul sistema."
        echo ""
        echo "  Installa uno dei seguenti e ri-esegui questo script:"
        echo "    • Claude Code:   https://claude.ai/code"
        echo "    • OpenCode:      https://github.com/opencode-ai/opencode"
        echo "    • GitHub Copilot: https://github.com/features/copilot"
        echo "    • Cursor:        https://cursor.sh"
        echo "    • Windsurf:      https://codeium.com/windsurf"
        echo "    • Codex:         https://openai.com/codex"
        echo ""
        echo "  Per installazione locale usa: $0 --local"
    fi

    echo ""
    echo -e "${CYAN}${BOLD}Vulcan${NC} — C# Development, Cloud-Native. ${BOLD}Ready.${NC}"
}

main "$@"
