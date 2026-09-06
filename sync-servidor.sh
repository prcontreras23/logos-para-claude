#!/bin/bash
# Para mantenimiento: trae la copia del servidor desde el fork de desarrollo
# (~/LogosBibleSoftwareMCP, rama con el PR abierto) a este repo de distribución.
# El código fuente del servidor vive allá; aquí solo se vendoriza para que el
# instalador sea autocontenido.
set -euo pipefail
ORIGEN="${1:-$HOME/LogosBibleSoftwareMCP/logos-mcp-server}"
DESTINO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/logos-mcp-server"
[[ -d "$ORIGEN/src" ]] || { echo "No encuentro $ORIGEN/src" >&2; exit 1; }
rsync -a --delete --exclude node_modules --exclude dist --exclude .env --exclude '*.db' --exclude .DS_Store "$ORIGEN/" "$DESTINO/"
echo "Servidor sincronizado desde $ORIGEN ($(cd "$ORIGEN/.." && git rev-parse --short HEAD 2>/dev/null || echo 'sin git'))"
