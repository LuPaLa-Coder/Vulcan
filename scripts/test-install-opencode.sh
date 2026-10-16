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

mkdir -p "$home_dir/.claude"
HOME="$home_dir" \
XDG_CONFIG_HOME="$xdg_config_dir" \
"$script_dir/install.sh" --agent claude

templates_dir="$home_dir/.claude/agents/vulcan-templates"
if [[ -e "$templates_dir" ]]; then
    echo "Claude Code installation unexpectedly created $templates_dir" >&2
    exit 1
fi
