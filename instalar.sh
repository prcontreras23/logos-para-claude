#!/bin/bash
# Arranque de una línea para Mac:
#
#   curl -fsSL https://raw.githubusercontent.com/prcontreras23/logos-para-claude/main/instalar.sh | bash
#
# Baja el proyecto y arranca el instalador de doble clic. Existe para esquivar
# Gatekeeper: un archivo descargado con el navegador queda marcado como "de
# internet" y macOS no lo ejecuta con doble clic si no está firmado. Lo que
# baja curl no lleva esa marca.

set -uo pipefail

REPO="prcontreras23/logos-para-claude"
FUENTE="$HOME/logos-para-claude-fuente"

rojo()  { printf '\033[31m%s\033[0m\n' "$*"; }
verde() { printf '\033[32m%s\033[0m\n' "$*"; }
gris()  { printf '\033[90m%s\033[0m\n' "$*"; }
morir() { echo; rojo "  ✗ $*"; echo; exit 1; }

[[ "$(uname -s)" == "Darwin" ]] || morir "Este arranque es para Mac. En Windows: irm https://raw.githubusercontent.com/$REPO/main/instalar-windows.ps1 | iex"

echo
printf '\033[1m%s\033[0m\n' "Bajando Logos para Claude..."
echo

rm -rf "$FUENTE"; mkdir -p "$FUENTE"
if ! curl -fsSL "https://github.com/$REPO/archive/refs/heads/main.tar.gz" | tar -xz -C "$FUENTE" --strip-components=1; then
  morir "No se pudo bajar. Revisa que tengas internet e inténtalo otra vez."
fi
chmod +x "$FUENTE/Instalar en Mac.command" "$FUENTE/install.sh" "$FUENTE/desinstalar.sh" 2>/dev/null
verde "  ✓ listo"
gris  "  archivos en $FUENTE"

# El instalador muestra diálogos y puede pedir datos; se le devuelve la terminal
# como entrada porque este script llega por una tubería.
if : < /dev/tty 2>/dev/null; then
  exec "$FUENTE/Instalar en Mac.command" < /dev/tty
else
  exec "$FUENTE/Instalar en Mac.command"
fi
