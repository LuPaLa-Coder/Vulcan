#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
REPO_ROOT=$PWD

failures=0

fail() {
  echo "ERROR: $*" >&2
  failures=$((failures + 1))
}

assert_contains() {
  local file="$1"
  local text="$2"
  grep -Fq -- "$text" "$file" || fail "$file does not contain: $text"
}

assert_not_contains() {
  local file="$1"
  local text="$2"
  if grep -Fq -- "$text" "$file"; then
    fail "$file still contains forbidden text: $text"
  fi
}

rule_value() {
  local kind="$1"
  local route="$2"
  awk -F '\t' -v kind="$kind" -v route="$route" '
    NR > 1 && $1 == kind && $2 == route { print $3; exit }
  ' contracts/routing-rules.tsv
}

route_prompt() {
  local prompt="$1"
  local lowered
  lowered=$(printf '%s' "$prompt" | tr '[:upper:]' '[:lower:]')

  local aws_match=0
  local azure_match=0
  local sca_match=0
  local write_match=0
  local mutation_match=0
  local aws_pattern azure_pattern sca_pattern write_pattern mutation_pattern
  local default_route conflict_route cloud_generic_pattern
  aws_pattern=$(rule_value domain Vulcan-AWS)
  azure_pattern=$(rule_value domain Vulcan-Azure)
  sca_pattern=$(rule_value domain Vulcan-SCA)
  write_pattern=$(rule_value intent WRITE)
  mutation_pattern=$(rule_value intent MUTATION)
  default_route=$(rule_value policy DEFAULT)
  conflict_route=$(rule_value policy CLOUD_CONFLICT)
  cloud_generic_pattern=$(rule_value policy CLOUD_GENERIC_PATTERN)

  if grep -Eqi "$aws_pattern" <<<"$lowered"; then
    aws_match=1
  fi
  if grep -Eqi "$azure_pattern" <<<"$lowered"; then
    azure_match=1
  fi
  if (( aws_match == 1 && azure_match == 1 )); then
    printf '%s' "$conflict_route"
    return
  fi
  if grep -Eqi "$sca_pattern" <<<"$lowered"; then
    sca_match=1
  fi
  if grep -Eqi "$write_pattern" <<<"$lowered"; then
    write_match=1
  fi
  if grep -Eqi "$mutation_pattern" <<<"$lowered"; then
    mutation_match=1
  fi
  if (( aws_match == 0 && azure_match == 0 && mutation_match == 1 )) &&
     grep -Eqi "$cloud_generic_pattern" <<<"$lowered"; then
    printf '%s' "$conflict_route"
    return
  fi

  local selected_route=""
  while IFS=$'\t' read -r kind route pattern; do
    [[ "$route" == "route" ]] && continue
    [[ "$kind" == "domain" || "$kind" == "workflow" ]] || continue
    [[ "$route" == "Vulcan-SCA" ]] && continue
    if grep -Eqi "$pattern" <<<"$lowered"; then
      selected_route="$route"
      break
    fi
  done < contracts/routing-rules.tsv

  [[ -n "$selected_route" ]] || selected_route="$default_route"

  if [[ "$selected_route" == *"->"* ]]; then
    printf '%s' "$selected_route"
  elif (( sca_match == 1 && mutation_match == 1 )); then
    printf '%s->Vulcan-SCA' "$selected_route"
  elif (( sca_match == 1 )); then
    printf 'Vulcan-SCA'
  else
    printf '%s' "$selected_route"
  fi
}

route_mode() {
  local prompt="$1"
  local write_pattern read_pattern
  write_pattern=$(rule_value intent WRITE)
  read_pattern=$(rule_value intent READ_ONLY)
  if grep -Eqi "$read_pattern" <<<"$prompt"; then
    printf 'read-only'
  elif grep -Eqi "$write_pattern" <<<"$prompt"; then
    printf 'write'
  else
    printf 'read-only'
  fi
}

validate_capabilities() {
  local rows=0
  while IFS=$'\t' read -r slug display profile mode tool read edit shell network confirm; do
    [[ "$slug" == "slug" ]] && continue
    rows=$((rows + 1))
    [[ -n "$display" && -n "$profile" ]] || fail "Incomplete capability row for $slug"
    [[ "$mode" == "native" || "$mode" == "handoff" ]] ||
      fail "Invalid delegation mode for $slug: $mode"
    if [[ "$mode" == "native" && "$tool" == "none" ]]; then
      fail "Native delegation requires a tool for $slug"
    fi
    if [[ "$mode" == "handoff" && "$tool" != "none" ]]; then
      fail "Handoff mode must not declare a delegation tool for $slug"
    fi
    for capability in "$read" "$edit" "$shell" "$network"; do
      [[ "$capability" == "true" || "$capability" == "false" || "$capability" == "host-managed" ]] ||
        fail "Invalid host capability for $slug: $capability"
    done
    [[ "$confirm" == "true" ]] || fail "Confirmation policy must be true for $slug"
    assert_contains install.sh "\"$display\""
  done < contracts/host-capabilities.tsv
  [[ "$rows" -eq 6 ]] || fail "Expected 6 host capability rows, found $rows"
}

validate_routing_cases() {
  while IFS=$'\t' read -r id prompt expected_route expected_mode; do
    [[ "$id" == "id" ]] && continue
    local actual_route actual_mode
    actual_route=$(route_prompt "$prompt")
    actual_mode=$(route_mode "$prompt" "$actual_route")
    [[ "$actual_route" == "$expected_route" ]] ||
      fail "$id route: expected $expected_route, got $actual_route"
    [[ "$actual_mode" == "$expected_mode" ]] ||
      fail "$id mode: expected $expected_mode, got $actual_mode"
  done < evals/routing-cases.tsv
}

validate_routing_rules() {
  while IFS=$'\t' read -r kind route pattern; do
    [[ "$kind" == "kind" ]] && continue
    [[ -n "$kind" && -n "$route" && -n "$pattern" ]] ||
      fail "Incomplete routing rule for $kind:$route"
  done < contracts/routing-rules.tsv

  local required
  for required in \
    "domain:Vulcan-SCA" \
    "domain:Vulcan-AWS" \
    "domain:Vulcan-Azure" \
    "domain:Vulcan-Patterns" \
    "domain:Vulcan-Core" \
    "intent:WRITE" \
    "intent:MUTATION" \
    "intent:READ_ONLY" \
    "policy:DEFAULT" \
    "policy:CLOUD_CONFLICT" \
    "policy:CLOUD_GENERIC_PATTERN"; do
    [[ -n "$(rule_value "${required%%:*}" "${required#*:}")" ]] ||
      fail "Missing required routing rule: $required"
  done
}

validate_agent_contracts() {
  assert_contains Vulcan.Dispatch.agent.md "Segnali provider-agnostic o nessun segnale cloud"
  assert_contains Vulcan.Dispatch.agent.md "handoff strutturato"
  assert_not_contains Vulcan.Dispatch.agent.md \
    '| RC-D6 | "crea API" senza target cloud | Chiede: "AWS, Azure o provider-agnostic?" |'

  assert_contains Vulcan.SCA.agent.md "High/Critical non vengono mai soppressi automaticamente"
  assert_contains Vulcan.SCA.agent.md \
    'NU1903` e `NU1904` non devono mai comparire in un blocco `NoWarn`'
  assert_contains Vulcan.SCA.agent.md "non dichiarare un revert automatico"
  assert_not_contains Vulcan.SCA.agent.md \
    "skippa quel finding con suppression tracciata"
  assert_not_contains Vulcan.SCA.agent.md \
    "Revert automatico, segnala [BLOCKER], passa al finding successivo"
  assert_not_contains Vulcan.SCA.agent.md \
    '<NoWarn>$(NoWarn);NU1903</NoWarn>'

  while IFS=$'\t' read -r id prompt expected_route expected_mode; do
    [[ "$id" == "id" ]] && continue
    assert_contains Vulcan.Dispatch.agent.md "| $id |"
    assert_contains Vulcan.Dispatch.agent.md "\`$expected_route\`"
  done < evals/routing-cases.tsv

  local allowed_without_eval=" RC-D8 RC-D11 "
  while IFS= read -r id; do
    if ! grep -q "^${id}"$'\t' evals/routing-cases.tsv &&
       [[ "$allowed_without_eval" != *" $id "* ]]; then
      fail "Documented regression ID has no eval or exemption: $id"
    fi
  done < <(
    grep -oE '\| RC-D[0-9]+ \|' Vulcan.Dispatch.agent.md |
      sed -E 's/\| (RC-D[0-9]+) \|/\1/'
  )
}

validate_installer_contracts() {
  assert_contains install.sh "contracts/host-capabilities.tsv"
  assert_contains install.sh "Host Capability Contract"
  assert_contains install.sh "delegation-mode:"

  local native_contract handoff_contract
  native_contract=$(
    VULCAN_INSTALLER_LIBRARY_ONLY=true bash -c '
      source ./install.sh
      SCRIPT_DIR=$PWD
      get_host_contract "Claude Code"
    '
  )
  handoff_contract=$(
    VULCAN_INSTALLER_LIBRARY_ONLY=true bash -c '
      source ./install.sh
      SCRIPT_DIR=$PWD
      get_host_contract "GitHub Copilot"
    '
  )
  grep -Fq -- "- delegation-mode: native" <<<"$native_contract" ||
    fail "Claude contract is not native"
  grep -Fq -- "- delegation-tool: Agent" <<<"$native_contract" ||
    fail "Claude contract does not expose Agent"
  grep -Fq -- "- delegation-mode: handoff" <<<"$handoff_contract" ||
    fail "Copilot contract is not handoff"
  grep -Fq -- "- delegation-tool: none" <<<"$handoff_contract" ||
    fail "Copilot handoff contract unexpectedly exposes a tool"

  local claude_sca opencode_dispatch generic_dispatch
  claude_sca=$(
    VULCAN_INSTALLER_LIBRARY_ONLY=true bash -c '
      source ./install.sh
      SCRIPT_DIR=$PWD
      get_frontmatter "Claude Code" "Vulcan.SCA.agent.md"
    '
  )
  opencode_dispatch=$(
    VULCAN_INSTALLER_LIBRARY_ONLY=true bash -c '
      source ./install.sh
      SCRIPT_DIR=$PWD
      get_frontmatter "OpenCode" "Vulcan.Dispatch.agent.md"
    '
  )
  generic_dispatch=$(
    VULCAN_INSTALLER_LIBRARY_ONLY=true bash -c '
      source ./install.sh
      SCRIPT_DIR=$PWD
      get_frontmatter "GitHub Copilot" "Vulcan.Dispatch.agent.md"
    '
  )
  grep -Fq -- "tools: Read, Grep, Glob, Bash, Agent" <<<"$claude_sca" ||
    fail "Claude SCA frontmatter lacks scan and delegation tools"
  grep -Fq -- 'version: "2026.10.7.1"' <<<"$claude_sca" ||
    fail "Claude SCA frontmatter lacks the agent version"
  grep -Fq -- "edit: deny" <<<"$opencode_dispatch" ||
    fail "OpenCode Dispatch can edit"
  grep -Fq -- "task: allow" <<<"$opencode_dispatch" ||
    fail "OpenCode Dispatch cannot delegate"
  if grep -Fq -- "tools:" <<<"$generic_dispatch"; then
    fail "Generic Dispatch frontmatter claims host-specific tools"
  fi
  grep -Fq -- 'version: "2026.10.7.1"' <<<"$generic_dispatch" ||
    fail "Generic Dispatch frontmatter lacks the agent version"

  local temp_dir
  temp_dir=$(mktemp -d)
  if ! (cd "$temp_dir" && bash "$REPO_ROOT/install.sh" --local >/dev/null); then
    fail "Local installer smoke test failed"
  else
    grep -Fq -- "- delegation-mode: native" \
      "$temp_dir/.claude/agents/Vulcan.Dispatch.agent.md" ||
      fail "Installed Dispatch lacks native delegation contract"
    grep -Fq -- "tools: Read, Grep, Glob, Bash, Agent" \
      "$temp_dir/.claude/agents/Vulcan.SCA.agent.md" ||
      fail "Installed SCA lacks required Claude tools"
  fi
  rm -rf "$temp_dir"
}

validate_medium_priority_contracts() {
  local agent
  for agent in \
    Vulcan.Core.agent.md \
    Vulcan.AWS.agent.md \
    Vulcan.Azure.agent.md \
    Vulcan.SCA.agent.md; do
    assert_contains "$agent" "<!-- BEGIN:PARTIAL:dependency-health-policy -->"
  done

  assert_not_contains Vulcan.SCA.agent.md \
    "0 vulnerabili · 0 deprecati · 0 outdated"
  assert_not_contains Vulcan.SCA.agent.md \
    "la migrazione a .NET 10 **precede** l'azzeramento degli outdated"
  assert_contains Vulcan.SCA.agent.md \
    "- Outdated residui: [N, con motivazione e piano]"

  assert_not_contains Vulcan.Patterns.agent.md "DateTimeOffset.UtcNow"
  assert_not_contains Vulcan.Patterns.agent.md "SemaphoreSlim> _gates"
  assert_contains Vulcan.Patterns.agent.md "TimeProvider clock"
  assert_contains Vulcan.Patterns.agent.md "_inflight.TryRemove(key, out _)"
  assert_contains Vulcan.Patterns.agent.md "<!-- BEGIN:PARTIAL:guardrail-common -->"
  assert_contains Vulcan.Patterns.agent.md "<!-- BEGIN:PARTIAL:profili-operativi -->"
  assert_contains Vulcan.SCA.agent.md "<!-- BEGIN:PARTIAL:guardrail-common -->"
  assert_contains Vulcan.Dispatch.agent.md "<!-- BEGIN:PARTIAL:guardrail-common -->"
  assert_contains Vulcan.Core.agent.md 'select((.package as $package | $findings | index($package)) == null)'
  assert_contains Vulcan.Core.agent.md 'all(.deprecated[]?;'
}

validate_dependency_exception_filter() {
  command -v jq >/dev/null || {
    fail "jq is required for dependency exception evals"
    return
  }

  local temp_dir today findings allowed expired stale invalid
  temp_dir=$(mktemp -d)
  today=$(date -u +%F)

  cat > "$temp_dir/dep.json" <<'JSON'
{"projects":[{"frameworks":[{"topLevelPackages":[{"id":"Allowed.Package","deprecationReasons":["Legacy"]},{"id":"Blocked.Package","deprecationReasons":["Legacy"]}],"transitivePackages":[]}]}]}
JSON
  cat > "$temp_dir/good.json" <<'JSON'
{"deprecated":[{"package":"Allowed.Package","reason":"migration pending","owner":"team-platform","expires":"2099-12-31","ticket":"PROJ-1"}]}
JSON
  cat > "$temp_dir/stale.json" <<'JSON'
{"deprecated":[{"package":"Ghost.Package","reason":"stale","owner":"team-platform","expires":"2099-12-31","ticket":"PROJ-2"}]}
JSON
  cat > "$temp_dir/expired.json" <<'JSON'
{"deprecated":[{"package":"Allowed.Package","reason":"expired","owner":"team-platform","expires":"2000-01-01","ticket":"PROJ-3"}]}
JSON
  cat > "$temp_dir/invalid.json" <<'JSON'
{"deprecated":[{"package":"Allowed.Package","expires":"2099-12-31"}]}
JSON

  findings=$(jq '[.projects[].frameworks[]? |
    (.topLevelPackages // [])[], (.transitivePackages // [])[] |
    select(.deprecationReasons) | .id] | unique' "$temp_dir/dep.json")
  allowed=$(jq -c --arg today "$today" \
    '[.deprecated[]? | select(.expires >= $today) | .package]' \
    "$temp_dir/good.json")
  [[ "$allowed" == '["Allowed.Package"]' ]] ||
    fail "Valid dependency exception was not loaded"

  expired=$(jq --arg today "$today" \
    '[.deprecated[]? | select(.expires < $today)] | length' \
    "$temp_dir/expired.json")
  [[ "$expired" -eq 1 ]] || fail "Expired dependency exception was not detected"

  stale=$(jq --argjson findings "$findings" --arg today "$today" \
    '[.deprecated[]? | select(.expires >= $today) |
      select((.package as $package | $findings | index($package)) == null)] |
      length' "$temp_dir/stale.json")
  [[ "$stale" -eq 1 ]] || fail "Stale dependency exception was not detected"

  if jq -e 'all(.deprecated[]?;
    (.package | type) == "string" and
    (.reason | type) == "string" and
    (.owner | type) == "string" and
    (.expires | type) == "string" and
    (.ticket | type) == "string")' "$temp_dir/invalid.json" >/dev/null; then
    invalid=0
  else
    invalid=1
  fi
  [[ "$invalid" -eq 1 ]] || fail "Invalid dependency exception schema was accepted"

  rm -rf "$temp_dir"
}

validate_capabilities
validate_routing_rules
validate_routing_cases
validate_agent_contracts
validate_installer_contracts
validate_medium_priority_contracts
validate_dependency_exception_filter

if (( failures > 0 )); then
  echo "Contract evals failed: $failures" >&2
  exit 1
fi

echo "Contract evals passed"
