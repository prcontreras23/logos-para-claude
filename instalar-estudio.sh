#!/bin/bash
# Solo el skill de estudio, para quien ya tiene Logos para Claude:
#
#   curl -fsSL https://raw.githubusercontent.com/prcontreras23/logos-para-claude/main/instalar-estudio.sh | bash
#
# Instala el skill «estudio-logos», el vault de Obsidian «Estudios bíblicos»
# y, si falta, Obsidian. Si estaba el método anterior (estudio-biblico), lo quita. No toca el servidor de Logos.

set -uo pipefail

REPO="prcontreras23/logos-para-claude"
FUENTE="$HOME/logos-para-claude-fuente"

morir() { echo; printf '\033[31m  ✗ %s\033[0m\n\n' "$*"; exit 1; }

[[ "$(uname -s)" == "Darwin" ]] || morir "Este arranque es para Mac. En Windows: irm https://raw.githubusercontent.com/$REPO/main/instalar-windows.ps1 | iex"

echo
printf '\033[1m%s\033[0m\n' "Bajando el skill de estudio..."
rm -rf "$FUENTE"; mkdir -p "$FUENTE"
curl -fsSL "https://github.com/$REPO/archive/refs/heads/main.tar.gz" | tar -xz -C "$FUENTE" --strip-components=1 \
  || morir "No se pudo bajar. Revisa que tengas internet e inténtalo otra vez."

# Queda también junto al servidor, para que install.sh y desinstalar.sh lo encuentren.
mkdir -p "$HOME/logos-para-claude"
rm -rf "$HOME/logos-para-claude/estudio-biblico"
cp -R "$FUENTE/estudio-biblico" "$HOME/logos-para-claude/estudio-biblico"

if : < /dev/tty 2>/dev/null; then
  bash "$HOME/logos-para-claude/estudio-biblico/instalar-estudio.sh" "$@" < /dev/tty
else
  bash "$HOME/logos-para-claude/estudio-biblico/instalar-estudio.sh" "$@"
fi
echo
printf '\033[32m  ✓\033[0m %s\n\n' "Listo. Cierra la app de Claude y vuelve a abrirla para que cargue el skill."
