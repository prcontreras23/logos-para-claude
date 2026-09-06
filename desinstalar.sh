#!/bin/bash
# Quita Logos para Claude de esta Mac: el registro en Claude Code, la entrada
# en Claude Desktop, los ayudantes compilados y la carpeta del servidor.
# No toca Logos ni sus datos.

set -uo pipefail

DESTINO="$HOME/logos-para-claude"
CFG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"

ok()   { printf '\033[32m  ✓\033[0m %s\n' "$*"; }
info() { printf '\033[90m  · %s\033[0m\n' "$*"; }

echo
printf '\033[1m%s\033[0m\n' "Desinstalando Logos para Claude"
echo

if command -v claude >/dev/null 2>&1; then
  claude mcp remove logos --scope user >/dev/null 2>&1 && ok "quitado de Claude Code" || info "no estaba registrado en Claude Code"
fi

if [[ -f "$CFG" ]] && command -v node >/dev/null 2>&1; then
  node -e '
    const fs = require("fs"); const p = process.argv[1];
    try { const c = JSON.parse(fs.readFileSync(p, "utf8")); if (c.mcpServers && c.mcpServers.logos) { delete c.mcpServers.logos; fs.writeFileSync(p, JSON.stringify(c, null, 2) + "\n"); process.exit(0); } } catch {}
    process.exit(1);
  ' "$CFG" 2>/dev/null && ok "quitado de Claude Desktop" || info "no estaba en Claude Desktop"
fi

rm -rf "$HOME/Library/Caches/logos-mcp" && ok "ayudantes de pantalla borrados"
rm -rf "$DESTINO" "$HOME/logos-para-claude-fuente" && ok "carpeta $DESTINO borrada"

echo
info "Los permisos de Accesibilidad y Grabación de pantalla los quitas tú en Ajustes del Sistema, si quieres."
echo
