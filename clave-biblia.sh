#!/bin/bash
# Agrega (o cambia) la clave de Biblia API después de instalar, sin reinstalar.
#
#   ~/logos-para-claude/clave-biblia.sh TU_CLAVE
#
# La clave se consigue gratis con tu cuenta de Faithlife (la misma de Logos):
#   https://api.biblia.com/v1/Users/SignIn
# Actualiza el registro en Claude Code y, si existe, la configuración de
# Claude Desktop. Reinicia Claude Code después.

set -uo pipefail

CLAVE="${1:-}"
CFG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"

ok()   { printf '\033[32m  ✓\033[0m %s\n' "$*"; }
info() { printf '\033[90m  · %s\033[0m\n' "$*"; }
morir() { printf '\033[31m  ✗ %s\033[0m\n' "$*" >&2; exit 1; }

if [[ -z "$CLAVE" ]]; then
  echo "Uso: $0 TU_CLAVE"
  echo
  info "Consíguela gratis en https://api.biblia.com/v1/Users/SignIn (entra con tu cuenta de Faithlife/Logos)."
  exit 1
fi
CLAVE="$(printf '%s' "$CLAVE" | tr -d '[:space:]')"
command -v claude >/dev/null 2>&1 || morir "No encuentro Claude Code (comando 'claude')."

# Leer el registro actual para conservar el comando y las demás variables.
LEIDO="$(node -e '
  const fs = require("fs"); const p = require("os").homedir() + "/.claude.json";
  const c = JSON.parse(fs.readFileSync(p, "utf8")); const s = c.mcpServers && c.mcpServers.logos;
  if (!s) process.exit(2);
  console.log(JSON.stringify({ command: s.command, args: s.args || [], env: s.env || {} }));
' 2>/dev/null)" || morir "El servidor 'logos' no está registrado en Claude Code. Corre primero el instalador."

CMD="$(printf '%s' "$LEIDO" | node -pe 'JSON.parse(require("fs").readFileSync(0,"utf8")).command')"
ARG0="$(printf '%s' "$LEIDO" | node -pe 'JSON.parse(require("fs").readFileSync(0,"utf8")).args[0]')"
ENVS=()
while IFS= read -r kv; do [[ -n "$kv" ]] && ENVS+=(--env "$kv"); done < <(
  printf '%s' "$LEIDO" | node -e '
    const s = JSON.parse(require("fs").readFileSync(0, "utf8")); s.env.BIBLIA_API_KEY = process.argv[1];
    for (const [k, v] of Object.entries(s.env)) console.log(k + "=" + v);
  ' "$CLAVE")

claude mcp remove logos --scope user >/dev/null 2>&1 || true
claude mcp add logos --scope user "${ENVS[@]}" -- "$CMD" "$ARG0" >/dev/null 2>&1 || morir "No pude volver a registrar el servidor en Claude Code."
ok "clave guardada en Claude Code"

if [[ -f "$CFG" ]]; then
  CLAVE="$CLAVE" node -e '
    const fs = require("fs"); const p = process.argv[1];
    try { const c = JSON.parse(fs.readFileSync(p, "utf8")); if (c.mcpServers && c.mcpServers.logos) { c.mcpServers.logos.env = Object.assign({}, c.mcpServers.logos.env, { BIBLIA_API_KEY: process.env.CLAVE }); fs.writeFileSync(p, JSON.stringify(c, null, 2) + "\n"); } } catch {}
  ' "$CFG" 2>/dev/null && ok "clave guardada en Claude Desktop"
fi

info "Reinicia Claude Code para que la use."
