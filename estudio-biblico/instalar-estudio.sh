#!/bin/bash
# Estudio en Logos para Claude — macOS
#
# Instala el skill «estudio-logos» (buscar, leer y estudiar en Logos a la manera
# de cada persona), un vault de Obsidian para los estudios y, si falta, Obsidian. Lo llama
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

SKILL_DIR="$HOME/.claude/skills/estudio-logos"
CONFIG="$SKILL_DIR/configuracion.md"
VIEJO_DIR="$HOME/.claude/skills/estudio-biblico"
VIEJO_AGENTE="$HOME/.claude/agents/lector-fuentes-logos.md"
VAULT_NOMBRE="$(basename "$VAULT")"

paso "Estudio en Logos"

# ---------------------------------------------------------------- nombre

# El nombre y el trato de una instalación anterior se conservan: primero del
# configuracion.md actual, si no del ajustes.json del método viejo (estudio-biblico).
leer_config() {  # campo
  [[ -f "$CONFIG" ]] || return 0
  sed -n "s/^- \*\*$1\*\*: *\([^<]*\).*/\1/p" "$CONFIG" | head -1 | sed 's/[[:space:]]*$//'
}
leer_viejo() {  # clave
  [[ -f "$VIEJO_DIR/ajustes.json" ]] || return 0
  plutil -extract "$1" raw -o - "$VIEJO_DIR/ajustes.json" 2>/dev/null || true
}
[[ -z "$NOMBRE" ]] && NOMBRE="$(leer_config nombre)"
[[ -z "$NOMBRE" ]] && NOMBRE="$(leer_viejo nombre)"
[[ -z "$TRATAMIENTO" ]] && TRATAMIENTO="$(leer_config tratamiento)"
[[ -z "$TRATAMIENTO" ]] && TRATAMIENTO="$(leer_viejo tratamiento)"
if [[ -z "$NOMBRE" && "${ESTUDIO_PREGUNTAR:-1}" != 0 ]] && : < /dev/tty 2>/dev/null; then
  printf '  ¿Cómo se llama la persona que va a estudiar? (Enter para dejarlo en blanco): '
  read -r NOMBRE < /dev/tty || NOMBRE=""
fi
[[ -z "$TRATAMIENTO" ]] && TRATAMIENTO="usted"

# ---------------------------------------------------------------- skill

mkdir -p "$SKILL_DIR"
# Se reemplazan los archivos del skill; configuracion.md es de la persona y no se toca.
find "$SKILL_DIR" -maxdepth 1 -type f ! -name configuracion.md -delete
cp "$AQUI/skill/estudio-logos/"* "$SKILL_DIR/"
ok "skill estudio-logos en $SKILL_DIR"

# El método anterior (skill estudio-biblico y agente lector-fuentes-logos) lo
# instalaba este mismo paquete; se quita para que no compita con el nuevo.
# Los estudios del vault no se tocan.
if [[ -d "$VIEJO_DIR" || -f "$VIEJO_AGENTE" ]]; then
  rm -rf "$VIEJO_DIR" "$VIEJO_AGENTE"
  ok "quitado el método anterior (estudio-biblico); sus estudios siguen en el vault"
fi

# ---------------------------------------------------------------- vault

mkdir -p "$VAULT"
( cd "$AQUI/vault" && find . -type d ) | while read -r d; do mkdir -p "$VAULT/$d"; done
( cd "$AQUI/vault" && find . -type f ) | while read -r f; do
  [[ -e "$VAULT/$f" ]] || cp "$AQUI/vault/$f" "$VAULT/$f"
done
ok "vault «$VAULT_NOMBRE» en $VAULT"

# ---------------------------------------------------------------- configuración

if [[ -f "$CONFIG" ]]; then
  ok "configuración existente conservada"
else
  if ! NOMBRE="$NOMBRE" TRATAMIENTO="$TRATAMIENTO" VAULT="$VAULT" node -e '
    const fs = require("fs");
    let s = fs.readFileSync(process.argv[1], "utf8");
    const poner = (campo, valor) => {
      s = s.replace(new RegExp("^(- \\*\\*" + campo + "\\*\\*:)[^<\\n]*", "m"), (_, a) => a + " " + valor + "    ");
    };
    poner("nombre", process.env.NOMBRE);
    poner("tratamiento", process.env.TRATAMIENTO);
    poner("guardar_en", process.env.VAULT);
    fs.writeFileSync(process.argv[2], s);
  ' "$SKILL_DIR/configuracion.ejemplo.md" "$CONFIG" 2>/dev/null; then
    cp "$SKILL_DIR/configuracion.ejemplo.md" "$CONFIG"
  fi
  ok "configuración creada${NOMBRE:+ para $NOMBRE}"
fi

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
info "Para estudiar: abre la app de Claude, pestaña Code, elige la carpeta «$VAULT_NOMBRE» y di «vamos a estudiar la Biblia». La primera vez, Claude le pregunta cómo estudia y lo deja anotado."
info "Para que Claude lea los comentarios sin mover el mouse, entra una vez a app.logos.com en el navegador de la app de Claude"
info "con tu cuenta de Logos, y activa ahí Settings → Accessibility → Enable limited view mode."
