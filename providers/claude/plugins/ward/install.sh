#!/bin/bash
set -e

GREEN='\033[0;32m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

step() { echo -e "  ${GREEN}✓${NC} $1"; }

CLAUDE_DIR="${1:-${HOME}/.claude}"
SCOPE="${2:-user}"
PLUGIN_NAME="ward"
MARKETPLACE_NAME="br4zz4"
PLUGINS_DIR="${CLAUDE_DIR}/plugins"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

mkdir -p "${PLUGINS_DIR}"

# --- marketplace: register in settings.json ---
if [ -f "${SETTINGS_FILE}" ] && command -v jq &>/dev/null; then
    tmp=$(mktemp)
    jq --arg name "${MARKETPLACE_NAME}" \
       --arg path "${PLUGINS_DIR}" \
       '.extraKnownMarketplaces[$name] = {"source": {"source": "directory", "path": $path}, "autoUpdate": true}' \
       "${SETTINGS_FILE}" > "$tmp" && mv "$tmp" "${SETTINGS_FILE}"
else
    mkdir -p "${CLAUDE_DIR}"
    cat > "${SETTINGS_FILE}" <<JSON
{
  "extraKnownMarketplaces": {
    "${MARKETPLACE_NAME}": {
      "source": { "source": "directory", "path": "${PLUGINS_DIR}" },
      "autoUpdate": true
    }
  }
}
JSON
fi
step "marketplace ${MARKETPLACE_NAME} registered"

# --- plugin: install ---
REF="${PLUGIN_NAME}@${MARKETPLACE_NAME}"
if ! claude plugin list 2>/dev/null | grep -q "${REF}"; then
    claude plugin install --scope "${SCOPE}" "${REF}"
    step "plugin ${REF} installed"
else
    echo -e "  ${GRAY}–${NC} plugin ${REF} (already installed)"
fi

echo -e "\n  ${BOLD}ward Claude plugin ready.${NC}\n"
