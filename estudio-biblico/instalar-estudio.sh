#!/bin/bash
# Método de estudio bíblico para Claude — macOS
#
# Instala el skill «estudio-biblico», el agente «lector-fuentes-logos», un vault
# de Obsidian para los estudios y, si falta, la app de Obsidian. Lo llama
# install.sh al final, y también se puede correr solo:
#
#   ./instalar-estudio.sh [--nombre "Juan Pérez"] [--tratamiento usted|tú] [--vault RUTA]
#
# Se puede correr varias veces: nunca borra ni pisa lo que el estudiante ya
# escribió en el vault.

set -uo pipefail

AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOMBRE=""
TRATAMIENTO=""
VAULT="$HOME/Documents/Estudios bíblicos"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --nombre) NOMBRE="$2"; shift 2 ;;
    --tratamiento) TRATAMIENTO="$2"; shift 2 ;;
    --vault) VAULT="$2"; shift 2 ;;
    *) shift ;;
  esac
done

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '\033[32m  ✓\033[0m %s\n' "$*"; }
info() { printf '\033[90m  · %s\033[0m\n' "$*"; }
warn() { printf '\033[33m  ! %s\033[0m\n' "$*"; }
paso() { echo; bold "$*"; }

SKILL_DIR="$HOME/.claude/skills/estudio-biblico"
AGENTES="$HOME/.claude/agents"
AJUSTES="$SKILL_DIR/ajustes.json"
VAULT_NOMBRE="$(basename "$VAULT")"

paso "Método de estudio bíblico"

# ---------------------------------------------------------------- nombre

# Si ya hay ajustes de una instalación anterior, se conservan.
leer_ajuste() {  # clave
  [[ -f "$AJUSTES" ]] || return 0
  plutil -extract "$1" raw -o - "$AJUSTES" 2>/dev/null || true
}
[[ -z "$NOMBRE" ]] && NOMBRE="$(leer_ajuste nombre)"
[[ -z "$TRATAMIENTO" ]] && TRATAMIENTO="$(leer_ajuste tratamiento)"
if [[ -z "$NOMBRE" && "${ESTUDIO_PREGUNTAR:-1}" != 0 ]] && : < /dev/tty 2>/dev/null; then
  printf '  ¿Cómo se llama la persona que va a estudiar? (Enter para dejarlo en blanco): '
  read -r NOMBRE < /dev/tty || NOMBRE=""
fi
[[ -z "$TRATAMIENTO" ]] && TRATAMIENTO="usted"

# ---------------------------------------------------------------- skill y agente

mkdir -p "$SKILL_DIR" "$AGENTES"
cp "$AQUI/skill/estudio-biblico/"* "$SKILL_DIR/"
cp "$AQUI/agentes/lector-fuentes-logos.md" "$AGENTES/"
ok "skill en $SKILL_DIR"
ok "agente lector-fuentes-logos en $AGENTES"

# ---------------------------------------------------------------- vault

mkdir -p "$VAULT"
( cd "$AQUI/vault" && find . -type d ) | while read -r d; do mkdir -p "$VAULT/$d"; done
( cd "$AQUI/vault" && find . -type f ) | while read -r f; do
  [[ -e "$VAULT/$f" ]] || cp "$AQUI/vault/$f" "$VAULT/$f"
done
ok "vault «$VAULT_NOMBRE» en $VAULT"

# ---------------------------------------------------------------- ajustes

escapar() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
cat > "$AJUSTES" <<JSON
{
  "nombre": "$(escapar "$NOMBRE")",
  "tratamiento": "$(escapar "$TRATAMIENTO")",
  "vault_ruta": "$(escapar "$VAULT")",
  "vault_nombre": "$(escapar "$VAULT_NOMBRE")",
  "notebooklm": {}
}
JSON
ok "ajustes guardados${NOMBRE:+ para $NOMBRE}"

# ---------------------------------------------------------------- Obsidian

obsidian_app() {
  for d in /Applications "$HOME/Applications"; do
    [[ -d "$d/Obsidian.app" ]] && { echo "$d/Obsidian.app"; return 0; }
  done
  return 1
}

if obsidian_app >/dev/null; then
  ok "Obsidian ya está instalado"
else
  info "instalando Obsidian..."
  if command -v brew >/dev/null 2>&1 && brew install --cask obsidian >/dev/null 2>&1; then
    ok "Obsidian instalado con Homebrew"
  else
    URL="$(curl -fsSL 'https://api.github.com/repos/obsidianmd/obsidian-releases/releases?per_page=15' 2>/dev/null \
      | grep -o '"browser_download_url": *"[^"]*/Obsidian-[0-9.]*\.dmg"' | head -1 | sed 's/.*"\(https[^"]*\)"/\1/')"
    DMG="$(mktemp -d)/Obsidian.dmg"
    if [[ -n "$URL" ]] && curl -fsSL "$URL" -o "$DMG"; then
      MNT="$(mktemp -d)"
      if hdiutil attach -nobrowse -quiet -mountpoint "$MNT" "$DMG"; then
        DESTINO_APP="/Applications"; [[ -w /Applications ]] || { DESTINO_APP="$HOME/Applications"; mkdir -p "$DESTINO_APP"; }
        cp -R "$MNT/Obsidian.app" "$DESTINO_APP/" && ok "Obsidian instalado en $DESTINO_APP"
        hdiutil detach -quiet "$MNT" || true
      else
        warn "no pude abrir el instalador de Obsidian"
      fi
      rm -f "$DMG"
    else
      warn "no pude bajar Obsidian"
    fi
  fi
fi
obsidian_app >/dev/null || warn "instala Obsidian desde https://obsidian.md y abre la carpeta «$VAULT» como vault"

# ---------------------------------------------------------------- registrar el vault

# Obsidian guarda su lista de vaults en obsidian.json. Se agrega el nuevo solo
# si Obsidian está cerrado (si está abierto, reescribe el archivo al salir).
CFG_OBS="$HOME/Library/Application Support/obsidian/obsidian.json"
if pgrep -x Obsidian >/dev/null 2>&1; then
  info "Obsidian está abierto: para agregar el vault, usa «Abrir carpeta como vault» y elige $VAULT"
elif command -v node >/dev/null 2>&1; then
  mkdir -p "$(dirname "$CFG_OBS")"
  if VAULT="$VAULT" node -e '
    const fs = require("fs"), crypto = require("crypto"), p = process.argv[1];
    let cfg = {}; try { cfg = JSON.parse(fs.readFileSync(p, "utf8")); } catch {}
    cfg.vaults = cfg.vaults || {};
    const ya = Object.values(cfg.vaults).some(v => v.path === process.env.VAULT);
    if (!ya) cfg.vaults[crypto.randomBytes(8).toString("hex")] = { path: process.env.VAULT, ts: Date.now(), open: true };
    fs.writeFileSync(p, JSON.stringify(cfg));
  ' "$CFG_OBS" 2>/dev/null; then
    ok "vault registrado en Obsidian"
  else
    info "abre Obsidian y usa «Abrir carpeta como vault» con $VAULT"
  fi
else
  info "abre Obsidian y usa «Abrir carpeta como vault» con $VAULT"
fi

echo
info "Para estudiar: abre la app de Claude, pestaña Code, elige la carpeta «$VAULT_NOMBRE» y di «vamos a estudiar la Biblia»."
info "Para que Claude lea los comentarios sin mover el mouse, entra una vez a app.logos.com en el navegador de la app de Claude"
info "con tu cuenta de Logos, y activa ahí Settings → Accessibility → Enable limited view mode."
