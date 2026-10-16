#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf -- "$tmp_dir"' EXIT

home_dir="$tmp_dir/home"
xdg_config_dir="$tmp_dir/config"
mkdir -p "$home_dir"

HOME="$home_dir" \
XDG_CONFIG_HOME="$xdg_config_dir" \
"$script_dir/install.sh" --agent opencode

installed_agent="$xdg_config_dir/opencode/agents/vulcan-dispatch.md"
if [[ ! -s "$installed_agent" ]]; then
    echo "OpenCode installation did not create $installed_agent" >&2
    exit 1
fi

# OpenCode scansiona ricorsivamente {agent,agents}/**/*.md: i template non
# devono finire nella directory agents, altrimenti diventano agent fantasma.
templates_dir="$xdg_config_dir/opencode/agents/vulcan-templates"
if [[ -e "$templates_dir" ]]; then
    echo "OpenCode installation leaked templates into $templates_dir" >&2
    exit 1
fi

# Claude Code e Copilot CLI passano dal plugin: install.sh deve rifiutarli
# senza scrivere nulla nei loro profili.
mkdir -p "$home_dir/.claude" "$home_dir/.copilot"
for rejected in claude copilot; do
    if HOME="$home_dir" XDG_CONFIG_HOME="$xdg_config_dir" \
        "$script_dir/install.sh" --agent "$rejected" >/dev/null 2>&1; then
        echo "install.sh --agent $rejected should be rejected (plugin only)" >&2
        exit 1
    fi
done
if [[ -e "$home_dir/.claude/agents" || -e "$home_dir/.copilot/agents" ]]; then
    echo "install.sh wrote into Claude Code / Copilot profiles" >&2
    exit 1
fi
