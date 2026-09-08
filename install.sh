#!/usr/bin/env bash
# =============================================================================
#  Vulcan C# Agent — Global Installer v3.0
#  Installa Vulcan-Dispatch, Vulcan-Core, Vulcan-AWS, Vulcan-Azure e Vulcan-SCA per tutti i coding agent
#  rilevati con frontmatter nativo:
#  Claude Code · OpenCode · GitHub Copilot · Cursor · Windsurf · Codex
#
#  Uso:
#    curl -fsSL https://raw.githubusercontent.com/LuPaLa-Coder/Vulcan/main/install.sh | bash
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
VULCAN_VERSION="3.2.0"
REPO_URL="https://raw.githubusercontent.com/LuPaLa-Coder/Vulcan/main"

# Sei agenti Vulcan — Dispatch, Core (Generic), Patterns (Advanced), AWS, Azure, SCA
AGENT_FILES=(
    "Vulcan.Dispatch.agent.md"
    "Vulcan.Core.agent.md"
    "Vulcan.Patterns.agent.md"
    "Vulcan.AWS.agent.md"
    "Vulcan.Azure.agent.md"
    "Vulcan.SCA.agent.md"
)

# Agente legacy (v1/v2) da rimuovere in upgrade
LEGACY_AGENT_FILE="Vulcan.agent.md"

# Estrae la description dal frontmatter YAML del file agente
# Prova locale prima, poi scarica da GitHub
get_agent_description() {
    local agent_file="$1"
    local src=""

    if [[ -f "$SCRIPT_DIR/$agent_file" ]]; then
        src="$SCRIPT_DIR/$agent_file"
    else
        src=$(mktemp)
        if command -v curl &>/dev/null; then
            curl -fsSL "${REPO_URL}/${agent_file}" -o "$src" 2>/dev/null || {
                rm -f "$src"
                echo "Unknown Agent" >&2
                return 1
            }
        elif command -v wget &>/dev/null; then
            wget -q "${REPO_URL}/${agent_file}" -O "$src" 2>/dev/null || {
                rm -f "$src"
                echo "Unknown Agent" >&2
                return 1
            }
        else
            echo "Unknown Agent" >&2
            return 1
        fi
    fi

    # Estrai il valore di 'description:' dal frontmatter YAML (fra i due ---)
    local desc
    desc=$(awk '
      BEGIN { in_frontmatter = 0 }
      /^---$/ { in_frontmatter++; next }
      in_frontmatter == 1 && /^description:/ {
        # Rimuovi il prefisso "description: " e le virgolette
        gsub(/^description: *"?/, ""); gsub(/"?$/, "")
        print
        exit
      }
    ' "$src")

    # Pulizia se è stato scaricato
    if [[ "$src" != "$SCRIPT_DIR/$agent_file" ]]; then
        rm -f "$src"
    fi

    echo "$desc"
}

# Template files da installare — vanno in una subdirectory per evitare
# che OpenCode/Copilot/Cursor li interpretino come agent separati
TEMPLATE_DIR="vulcan-templates"
TEMPLATE_FILES=(
    "vulcan-aws-templates.md"
    "vulcan-azure-templates.md"
)

# Cache per i corpi degli agenti (scaricati/letti una volta sola)
# Cinque variabili invece di array associativo per compatibilità POSIX
_BODY_DISPATCH=""
_BODY_CORE=""
_BODY_AWS=""
_BODY_AZURE=""
_BODY_SCA=""

# Mappa il nome file agente al nome della variabile cache
get_body_varname() {
    case "$1" in
        "Vulcan.Dispatch.agent.md") echo "_BODY_DISPATCH" ;;
        "Vulcan.Core.agent.md") echo "_BODY_CORE" ;;
        "Vulcan.AWS.agent.md")  echo "_BODY_AWS" ;;
        "Vulcan.Azure.agent.md") echo "_BODY_AZURE" ;;
        "Vulcan.SCA.agent.md") echo "_BODY_SCA" ;;
    esac
}

# ── Banner ───────────────────────────────────────────────────────────────────
print_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "  ⚡ Vulcan C# Agent — Global Installer v${VULCAN_VERSION}"
    echo -e "${NC}"
    echo "  C# .NET 10 LTS · Vulcan-Dispatch · Vulcan-Core · Vulcan-AWS · Vulcan-Azure · Vulcan-SCA"
    echo "  Cloud-Native Development Agents"
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
    local agent_file="$1"
    local varname
    varname=$(get_body_varname "$agent_file")

    # Usa la cache se già popolata
    eval "local cached=\"\${$varname:-}\""
    if [[ -n "$cached" ]]; then
        echo "$cached"
        return 0
    fi

    local src=""

    if [[ -f "$SCRIPT_DIR/$agent_file" ]]; then
        src="$SCRIPT_DIR/$agent_file"
    else
        src=$(mktemp)
        if command -v curl &>/dev/null; then
            curl -fsSL "${REPO_URL}/${agent_file}" -o "$src" || {
                rm -f "$src"
                echo -e "${RED}✗${NC} Download fallito da ${REPO_URL}/${agent_file}" >&2
                return 1
            }
        elif command -v wget &>/dev/null; then
            wget -q "${REPO_URL}/${agent_file}" -O "$src" || {
                rm -f "$src"
                echo -e "${RED}✗${NC} Download fallito da ${REPO_URL}/${agent_file}" >&2
                return 1
            }
        else
            echo -e "${RED}✗${NC} Nessuno tra curl o wget disponibile. Installa curl e riprova." >&2
            return 1
        fi
    fi

    # Estrai il corpo: salta tutto fino al secondo --- (fine frontmatter YAML)
    local body
    body=$(awk '
      BEGIN { c = 0 }
      /^---$/ && c < 2 { c++; next }
      c >= 2 { print }
    ' "$src")

    # Salva in cache
    eval "$varname=\"\$body\""

    # Pulizia se è stato scaricato in tmp
    if [[ "$src" != "$SCRIPT_DIR/$agent_file" ]]; then
        rm -f "$src"
    fi

    echo "$body"
}

# ── Template Files ───────────────────────────────────────────────────────────
# Copia i file template (AWS, Azure) nella directory dell'agente.
# Prova prima dal repo locale (docs/), poi scarica da GitHub.

copy_templates() {
    local target_dir="$1"
    local tmpl_dir="${target_dir}/${TEMPLATE_DIR}"
    mkdir -p "$tmpl_dir"
    local copied=0

    for tmpl in "${TEMPLATE_FILES[@]}"; do
        local dest="${tmpl_dir}/${tmpl}"

        # Backup se richiesto
        if [[ "$DO_BACKUP" == "true" ]] && [[ -f "$dest" ]]; then
            cp "$dest" "${dest}.backup-$(date +%Y%m%d-%H%M%S)"
        fi

        if [[ -f "$SCRIPT_DIR/docs/$tmpl" ]]; then
            cp "$SCRIPT_DIR/docs/$tmpl" "$dest"
        elif command -v curl &>/dev/null; then
            curl -fsSL "${REPO_URL}/docs/${tmpl}" -o "$dest" || { rm -f "$dest"; continue; }
        elif command -v wget &>/dev/null; then
            wget -q "${REPO_URL}/docs/${tmpl}" -O "$dest" || { rm -f "$dest"; continue; }
        else
            continue
        fi

        ((copied++)) || true
    done

    if [[ $copied -gt 0 ]]; then
        echo -e "  ${GREEN}✓${NC} ${copied} template → ${tmpl_dir}/"
    fi
}

# ── Frontmatter per piattaforma ──────────────────────────────────────────────
# Claude Code: name + description, tools ereditati dall'host
# OpenCode:    description + mode + permission (oggetto con allow/deny per tool)
# Generico:    name + description (Copilot, Cursor, Windsurf, Codex)

get_frontmatter() {
    local platform="$1"  # claude | opencode | generic
    local agent_file="$2"

    local desc short_name
    desc=$(get_agent_description "$agent_file")
    short_name=$(get_agent_short_name "$agent_file")

    case "$platform" in
        claude|generic)
            echo "---"
            echo "name: Vulcan-${short_name}"
            echo "description: \"${desc}\""
            echo "---"
            ;;
        opencode)
            echo "---"
            echo "description: \"${desc}\""
            echo "mode: all"
            cat <<'EOF'
permission:
  read: allow
  edit: allow
  glob: allow
  grep: allow
  list: allow
  bash: allow
  task: allow
  webfetch: allow
  websearch: allow
  lsp: allow
  skill: allow
---
EOF
            ;;
    esac
}

# Estrae il nome breve dell'agente dal filename
# Vulcan.Dispatch.agent.md → Dispatch, Vulcan.Core.agent.md → Core, Vulcan.AWS.agent.md → AWS, Vulcan.Azure.agent.md → Azure, Vulcan.SCA.agent.md → SCA
get_agent_short_name() {
    local agent_file="$1"
    if [[ "$agent_file" == *".Dispatch."* ]]; then echo "Dispatch"
    elif [[ "$agent_file" == *".Core."* ]]; then echo "Core"
    elif [[ "$agent_file" == *".AWS."* ]]; then echo "AWS"
    elif [[ "$agent_file" == *".Azure."* ]]; then echo "Azure"
    elif [[ "$agent_file" == *".SCA."* ]]; then echo "SCA"
    else echo ""
    fi
}

# Mappa il nome del coding agent al tipo di piattaforma per il frontmatter
get_platform() {
    case "$1" in
        "OpenCode") echo "opencode" ;;
        "Claude Code")               echo "claude" ;;
        *)                           echo "generic" ;;
    esac
}

# ── Agent Directories ────────────────────────────────────────────────────────

get_agent_dirs() {
    local agent="$1"  # vuoto = tutti, oppure nome specifico
    local xdg_config="${XDG_CONFIG_HOME:-$HOME/.config}"

    case "$OS" in
        macos|linux)
            if [[ -z "$agent" || "$agent" == "claude" ]]; then
                if command -v claude &>/dev/null || [[ -d "$HOME/.claude" ]]; then
                    printf '%s|%s\n' "$HOME/.claude/agents" "Claude Code"
                fi
            fi

            if [[ -z "$agent" || "$agent" == "opencode" ]]; then
                if [[ -d "$xdg_config/opencode/agents" ]]; then
                    printf '%s|%s\n' "$xdg_config/opencode/agents" "OpenCode"
                fi
            fi

            if [[ -z "$agent" || "$agent" == "copilot" ]]; then
                if [[ -d "$HOME/.copilot" ]]; then
                    printf '%s|%s\n' "$HOME/.copilot/agents" "GitHub Copilot"
                fi
            fi

            if [[ -z "$agent" || "$agent" == "cursor" ]]; then
                if [[ -d "$HOME/.cursor" ]] && [[ -d "$HOME/.cursor/agents" ]]; then
                    printf '%s|%s\n' "$HOME/.cursor/agents" "Cursor"
                fi
            fi

            if [[ -z "$agent" || "$agent" == "windsurf" ]]; then
                if [[ -d "$HOME/.windsurf" ]] && [[ -d "$HOME/.windsurf/agents" ]]; then
                    printf '%s|%s\n' "$HOME/.windsurf/agents" "Windsurf"
                fi
            fi

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
                printf '%s|%s\n' "$appdata/opencode/agents" "OpenCode"
            fi
            if [[ -z "$agent" || "$agent" == "copilot" ]]; then
                printf '%s|%s\n' "$HOME/.copilot/agents" "GitHub Copilot"
            fi
            if [[ -z "$agent" || "$agent" == "cursor" ]]; then
                printf '%s|%s\n' "$appdata/Cursor/agents" "Cursor"
            fi
            if [[ -z "$agent" || "$agent" == "windsurf" ]]; then
                printf '%s|%s\n' "$appdata/Windsurf/agents" "Windsurf"
            fi
            if [[ -z "$agent" || "$agent" == "codex" ]]; then
                printf '%s|%s\n' "$HOME/.codex/agents" "OpenAI Codex"
            fi
            ;;
    esac
}

# ── Installa un singolo agente ────────────────────────────────────────────────
install_one_agent() {
    local target_dir="$1"
    local agent_name="$2"       # es. "Claude Code"
    local agent_file="$3"       # es. "Vulcan.Core.agent.md"
    local platform
    platform=$(get_platform "$agent_name")

    local short_name
    short_name=$(get_agent_short_name "$agent_file")

    # Per OpenCode il filename diventa vulcan-core.md, vulcan-aws.md, vulcan-azure.md
    local dest_filename="$agent_file"
    if [[ "$platform" == "opencode" ]]; then
        dest_filename="vulcan-$(echo "$short_name" | tr '[:upper:]' '[:lower:]').md"
    fi

    mkdir -p "$target_dir"
    local dest="${target_dir}/${dest_filename}"

    # Backup solo se richiesto esplicitamente con --backup
    if [[ "$DO_BACKUP" == "true" ]] && [[ -f "$dest" ]]; then
        local backup="${dest}.backup-$(date +%Y%m%d-%H%M%S)"
        cp "$dest" "$backup"
        echo -e "  ${YELLOW}↻${NC} Backup creato: ${backup}"
    fi

    # Genera il file con frontmatter specifico per la piattaforma + corpo
    {
        get_frontmatter "$platform" "$agent_file"
        echo ""
        get_agent_body "$agent_file"
    } > "$dest"

    if [[ -s "$dest" ]]; then
        echo -e "  ${GREEN}✓${NC} Vulcan-${short_name} installato per ${BOLD}${agent_name}${NC} (${platform})"
        echo -e "          → ${dest}"
        return 0
    else
        echo -e "  ${RED}✗${NC} Generazione fallita per Vulcan-${short_name} su ${agent_name}"
        return 1
    fi
}

# ── Installa tutti gli agenti ─────────────────────────────────────────────────
install_agent() {
    local target_dir="$1"
    local agent_name="$2"
    local installed=0
    local failed=0

    for agent_file in "${AGENT_FILES[@]}"; do
        if install_one_agent "$target_dir" "$agent_name" "$agent_file"; then
            installed=$((installed + 1))
        else
            failed=$((failed + 1))
        fi
    done

    # Copia i template una sola volta dopo tutti gli agenti
    copy_templates "$target_dir"

    # Rimuovi eventuale agente legacy (v1/v2)
    remove_legacy_agent "$target_dir" "$agent_name"

    return $failed
}

# ── Rimuovi agente legacy (v1/v2) ────────────────────────────────────────────
remove_legacy_agent() {
    local target_dir="$1"
    local agent_name="$2"
    local platform
    platform=$(get_platform "$agent_name")

    local legacy_filename="$LEGACY_AGENT_FILE"
    if [[ "$platform" == "opencode" ]]; then
        legacy_filename="vulcan.md"
    fi

    local legacy_path="${target_dir}/${legacy_filename}"
    if [[ -f "$legacy_path" ]]; then
        rm "$legacy_path"
        echo -e "  ${YELLOW}↻${NC} Rimosso agente legacy v1/v2: ${legacy_filename}"
    fi
}

# ── Uninstall ────────────────────────────────────────────────────────────────
uninstall_agent() {
    local target_dir="$1"
    local agent_name="$2"
    local platform
    platform=$(get_platform "$agent_name")

    local removed=0

    for agent_file in "${AGENT_FILES[@]}"; do
        local short_name
        short_name=$(get_agent_short_name "$agent_file")

        local dest_filename="$agent_file"
        if [[ "$platform" == "opencode" ]]; then
            dest_filename="vulcan-$(echo "$short_name" | tr '[:upper:]' '[:lower:]').md"
        fi
        local dest="${target_dir}/${dest_filename}"

        if [[ -f "$dest" ]]; then
            rm "$dest"
            echo -e "  ${GREEN}✓${NC} Vulcan-${short_name} rimosso da ${BOLD}${agent_name}${NC}"
            removed=$((removed + 1))
        fi
    done

    # Rimuovi anche l'agente legacy
    local legacy_filename="$LEGACY_AGENT_FILE"
    if [[ "$platform" == "opencode" ]]; then
        legacy_filename="vulcan.md"
    fi
    local legacy_path="${target_dir}/${legacy_filename}"
    if [[ -f "$legacy_path" ]]; then
        rm "$legacy_path"
        echo -e "  ${GREEN}✓${NC} Agente legacy Vulcan rimosso da ${BOLD}${agent_name}${NC}"
    fi

    # Rimuovi la directory dei template
    rm -rf "${target_dir}/${TEMPLATE_DIR}"

    if [[ $removed -eq 0 ]] && [[ ! -f "$legacy_path" ]]; then
        echo -e "  ${YELLOW}○${NC} Nessun agente Vulcan presente per ${agent_name}"
    fi
}

# ── Local Install ────────────────────────────────────────────────────────────
install_local() {
    local local_dir="${1:-$PWD}"
    local dest_dir="${local_dir}/.claude/agents"

    mkdir -p "$dest_dir"

    # Installa tutti e cinque gli agenti localmente con frontmatter Claude
    local installed=0
    for agent_file in "${AGENT_FILES[@]}"; do
        local dest="${dest_dir}/${agent_file}"

        {
            get_frontmatter "claude" "$agent_file"
            echo ""
            get_agent_body "$agent_file"
        } > "$dest"

        if [[ -s "$dest" ]]; then
            local short_name
            short_name=$(get_agent_short_name "$agent_file")
            echo -e "  ${GREEN}✓${NC} Vulcan-${short_name} installato localmente"
            echo -e "          → ${dest}"
            installed=$((installed + 1))
        else
            echo -e "  ${RED}✗${NC} Installazione locale fallita per ${agent_file}"
            return 1
        fi
    done

    # Template
    copy_templates "$dest_dir"

    # Crea settings.json Claude Code con tutti e cinque gli agenti
    local settings="${local_dir}/.claude/settings.json"
    if [[ ! -f "$settings" ]]; then
        cat > "$settings" <<'SETTINGS'
{
  "agents": {
    "Vulcan-Dispatch": {
      "description": "Vulcan-Dispatch — entry point e smistatore automatico",
      "path": ".claude/agents/Vulcan.Dispatch.agent.md"
    },
    "Vulcan-Core": {
      "description": "Vulcan-Core C# Agent — sviluppo .NET provider-agnostic",
      "path": ".claude/agents/Vulcan.Core.agent.md"
    },
    "Vulcan-AWS": {
      "description": "Vulcan-AWS C# Agent — sviluppo cloud-native AWS",
      "path": ".claude/agents/Vulcan.AWS.agent.md"
    },
    "Vulcan-Azure": {
      "description": "Vulcan-Azure C# Agent — sviluppo cloud-native Azure",
      "path": ".claude/agents/Vulcan.Azure.agent.md"
    },
    "Vulcan-SCA": {
      "description": "Vulcan-SCA — analisi e remediation NuGet dependencies",
      "path": ".claude/agents/Vulcan.SCA.agent.md"
    }
  }
}
SETTINGS
        echo -e "  ${GREEN}✓${NC} Creato .claude/settings.json con registrazione agenti"
    fi
}

# ── Verifica connessione ─────────────────────────────────────────────────────
check_connectivity() {
    # Verifica che possiamo ottenere almeno un corpo agente prima di procedere
    for agent_file in "${AGENT_FILES[@]}"; do
        if get_agent_body "$agent_file" > /dev/null 2>&1; then
            return 0
        fi
    done
    return 1
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
                echo "  --backup           Crea backup dei file agent esistenti prima di sovrascrivere"
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
                echo ""
                echo "Agenti Vulcan installati:"
                echo "  Vulcan-Dispatch — entry point e smistatore automatico"
                echo "  Vulcan-Core   — sviluppo .NET provider-agnostic"
                echo "  Vulcan-AWS    — sviluppo cloud-native AWS (Lambda, DynamoDB, SQS, CDK)"
                echo "  Vulcan-Azure  — sviluppo cloud-native Azure (Functions, Cosmos DB, Service Bus, Bicep)"
                echo "  Vulcan-SCA    — analisi e remediation dipendenze NuGet"
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
        if [[ -n "$target_agent" ]]; then
            echo -e "${YELLOW}⚠${NC} --local e --agent sono mutualmente esclusivi. --local installa nella directory corrente."
        fi
        echo -e "${BOLD}Installazione locale di Vulcan (Dispatch + Core + AWS + Azure + SCA)${NC}"
        echo ""
        install_local
        echo ""
        echo -e "${GREEN}${BOLD}✓${NC} Vulcan installato localmente (Dispatch + Core + AWS + Azure + SCA)!"
        echo ""
        echo "  Agenti disponibili: Vulcan-Dispatch, Vulcan-Core, Vulcan-AWS, Vulcan-Azure, Vulcan-SCA"
        echo "  Per usarli: seleziona l'agente dal menu quando richiesto."
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
    echo -e "${BOLD}Installazione globale di Vulcan (Dispatch + Core + AWS + Azure + SCA)${NC}"
    echo -e "  OS rilevato: ${CYAN}${OS}${NC}"
    echo ""

    # Verifica che possiamo ottenere almeno un corpo agente prima di procedere
    if ! check_connectivity; then
        echo -e "${RED}✗${NC} Impossibile accedere ai file agenti. Verifica la connessione."
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
    echo -e "${CYAN}${BOLD}Vulcan${NC} — Vulcan-Dispatch · Vulcan-Core · Vulcan-AWS · Vulcan-Azure · Vulcan-SCA. ${BOLD}Ready.${NC}"
}

main "$@"
