#!/bin/bash
# Instalador de Logos para Claude — macOS (terminal)
#
# Deja tu biblioteca de Logos conectada a Claude Code. Se puede correr varias
# veces sin problema: lo que ya está hecho se salta.
#
#   ./install.sh                         instala
#   ./install.sh --biblia RVR60          Biblia por defecto para las herramientas de texto
#   ./install.sh --clave-biblia XXXX     clave gratuita de bibliaapi.com (opcional)
#   ./install.sh --sin-desktop           no tocar la configuración de Claude Desktop

set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESTINO="$HOME/logos-para-claude"
SERVIDOR="$DESTINO/logos-mcp-server"
BIBLIA_DEFECTO="RVR60"
CLAVE_BIBLIA="${BIBLIA_API_KEY:-}"
TOCAR_DESKTOP=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --biblia) BIBLIA_DEFECTO="$2"; shift 2 ;;
    --clave-biblia) CLAVE_BIBLIA="$2"; shift 2 ;;
    --sin-desktop) TOCAR_DESKTOP=false; shift ;;
    *) shift ;;
  esac
done

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '\033[32m  ✓\033[0m %s\n' "$*"; }
info() { printf '\033[90m  · %s\033[0m\n' "$*"; }
warn() { printf '\033[33m  ! %s\033[0m\n' "$*"; }
err()  { printf '\033[31m  ✗ %s\033[0m\n' "$*" >&2; }
paso() { echo; bold "$*"; }
morir() { echo; err "$*"; echo; exit 1; }

echo
bold "═══ Logos para Claude ═══"
echo
info "Conecta tu biblioteca de Logos con Claude Code: leer comentarios como texto,"
info "buscar en tu catálogo, tus notas, sermones y planes de lectura."
echo

[[ "$(uname -s)" == "Darwin" ]] || morir "Este instalador es para Mac. En Windows usa install.ps1"

# shellcheck source=lib-requisitos.sh
source "$REPO_DIR/lib-requisitos.sh" || morir "Falta el archivo lib-requisitos.sh"
ruta_extendida

# ---------------------------------------------------------------- 1. requisitos

paso "1. Revisando lo que hace falta"
tiene_logos && ok "Logos Bible Software" || warn "no encuentro Logos en /Applications (el servidor funciona igual, pero sin la app no hay nada que leer)"
node_sirve && ok "Node.js $(node -v)" || info "falta Node.js 20+"
tiene_clt && ok "Command Line Tools (clang, swiftc)" || info "faltan las Command Line Tools"
tiene claude && ok "Claude Code" || info "falta Claude Code"

paso "2. Instalando lo que falta"
if ! node_sirve; then
  info "instalando Node.js (puede tardar un par de minutos)..."
  instalar_node && ok "Node.js $(node -v)" || morir "No pude instalar Node.js.
Instálalo desde https://nodejs.org (versión LTS) y vuelve a correr este instalador."
fi
if ! tiene_clt; then
  instalar_clt && ok "Command Line Tools" || warn "sin Command Line Tools: todo funciona menos leer el texto de los paneles y las capturas. Instálalas con: xcode-select --install"
fi
if ! tiene claude; then
  info "instalando Claude Code..."
  instalar_claude && ok "Claude Code" || warn "no pude instalar Claude Code; instálalo después con: curl -fsSL https://claude.ai/install.sh | bash"
fi
persistir_ruta

# ---------------------------------------------------------------- 3. copiar y compilar

paso "3. Copiando el servidor"
mkdir -p "$DESTINO"
if [[ "$REPO_DIR" != "$DESTINO" ]]; then
  rm -rf "$SERVIDOR"
  cp -R "$REPO_DIR/logos-mcp-server" "$SERVIDOR"
  cp "$REPO_DIR/lib-requisitos.sh" "$REPO_DIR/desinstalar.sh" "$REPO_DIR/clave-biblia.sh" "$DESTINO/" 2>/dev/null
  [[ -f "$REPO_DIR/LICENSE" ]] && cp "$REPO_DIR/LICENSE" "$DESTINO/"
fi
chmod +x "$DESTINO/desinstalar.sh" "$DESTINO/clave-biblia.sh" 2>/dev/null
ok "en $DESTINO"

paso "4. Preparando el servidor"
info "la primera vez baja dependencias y compila; toma uno o dos minutos"
cd "$SERVIDOR" || morir "No encuentro los archivos del servidor."
npm install --no-audit --no-fund --loglevel=error 2>&1 | grep -v "allow-scripts" | tail -3
# El motor SQLite es un módulo nativo. Si npm bloqueó su script de instalación,
# se compila aquí a mano.
if ! node -e 'require("better-sqlite3")' >/dev/null 2>&1; then
  info "preparando el motor SQLite..."
  npm rebuild better-sqlite3 --loglevel=error >/dev/null 2>&1
fi
node -e 'require("better-sqlite3")' >/dev/null 2>&1 || morir "El motor SQLite no quedó listo. Revisa que tengas internet y las Command Line Tools, y vuelve a correr el instalador."
npm run build --loglevel=error 2>&1 | grep -iE "error" && morir "La compilación falló."
[[ -f "$SERVIDOR/dist/index.js" ]] || morir "La compilación no produjo dist/index.js."
ok "compilado"

if tiene_clt; then
  info "compilando los ayudantes de pantalla..."
  node -e '
    Promise.all([
      import("./dist/services/screenshot-capture.js").then(m => m.ensureHelper()),
      import("./dist/services/panel-text.js").then(m => m.ensureDragHelper()),
    ]).then(() => process.exit(0)).catch(e => { console.error(String(e.message||e)); process.exit(1); });
  ' >/dev/null 2>&1 && ok "ayudantes listos" || warn "los ayudantes se compilarán la primera vez que se usen"
fi

# ---------------------------------------------------------------- 5. Logos

paso "5. Buscando tu biblioteca de Logos"
PERFIL="$(perfil_logos || true)"
if [[ -n "$PERFIL" ]]; then
  ok "perfil $PERFIL con catálogo"
else
  warn "no encontré el catálogo de Logos. Abre Logos una vez, deja que sincronice, y vuelve a correr este instalador si las herramientas de biblioteca fallan."
fi

# ---------------------------------------------------------------- 6. Claude Code

paso "6. Conectando con Claude Code"
NODE_BIN="$(command -v node)"
ENVS=(--env "LOGOS_DEFAULT_BIBLE=$BIBLIA_DEFECTO")
[[ -n "$CLAVE_BIBLIA" ]] && ENVS+=(--env "BIBLIA_API_KEY=$CLAVE_BIBLIA")
MCP_OK=false
if tiene claude; then
  claude mcp remove logos --scope user >/dev/null 2>&1 || true
  if claude mcp add logos --scope user "${ENVS[@]}" -- "$NODE_BIN" "$SERVIDOR/dist/index.js" >/dev/null 2>&1; then
    ok "servidor 'logos' registrado en Claude Code (Biblia por defecto: $BIBLIA_DEFECTO)"
    MCP_OK=true
  else
    warn "no pude registrarlo automáticamente. Hazlo con:
    claude mcp add logos --scope user --env LOGOS_DEFAULT_BIBLE=$BIBLIA_DEFECTO -- \"$NODE_BIN\" \"$SERVIDOR/dist/index.js\""
  fi
else
  warn "Claude Code no está instalado; cuando lo instales, vuelve a correr este instalador"
fi
if [[ -z "$CLAVE_BIBLIA" ]]; then
  info "sin clave de Biblia API: las herramientas de texto bíblico por internet quedan apagadas; todo lo de Logos funciona igual"
  info "para activarlas: entra con tu cuenta de Faithlife (la de Logos) en https://api.biblia.com/v1/Users/SignIn,"
  info "crea una clave (dirección web: localhost) y luego corre:  $DESTINO/clave-biblia.sh TU_CLAVE"
fi

# ---------------------------------------------------------------- 7. Claude Desktop (opcional)

if $TOCAR_DESKTOP && [[ -d "/Applications/Claude.app" || -d "$HOME/Applications/Claude.app" ]]; then
  paso "7. Claude Desktop"
  CFG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
  mkdir -p "$(dirname "$CFG")"
  [[ -f "$CFG" ]] || echo '{}' > "$CFG"
  if NODE_BIN="$NODE_BIN" SERVIDOR="$SERVIDOR" BIBLIA_DEFECTO="$BIBLIA_DEFECTO" CLAVE_BIBLIA="$CLAVE_BIBLIA" node -e '
    const fs = require("fs"); const p = process.argv[1];
    let cfg = {}; try { cfg = JSON.parse(fs.readFileSync(p, "utf8") || "{}"); } catch { cfg = {}; }
    cfg.mcpServers = cfg.mcpServers || {};
    const env = { LOGOS_DEFAULT_BIBLE: process.env.BIBLIA_DEFECTO };
    if (process.env.CLAVE_BIBLIA) env.BIBLIA_API_KEY = process.env.CLAVE_BIBLIA;
    cfg.mcpServers.logos = { command: process.env.NODE_BIN, args: [process.env.SERVIDOR + "/dist/index.js"], env };
    fs.writeFileSync(p, JSON.stringify(cfg, null, 2) + "\n");
  ' "$CFG" 2>/dev/null; then
    ok "agregado a claude_desktop_config.json (reinicia Claude Desktop para verlo)"
  else
    warn "no pude editar la configuración de Claude Desktop"
  fi
fi

# ---------------------------------------------------------------- 8. diagnóstico

paso "8. Comprobando"
DIAG="$(cd "$SERVIDOR" && node dist/cli.js 2>/dev/null || true)"
ENCONTRADAS="$(printf '%s\n' "$DIAG" | grep -c '✓ [a-zA-Z]' || true)"
FALTAN="$(printf '%s\n' "$DIAG" | grep -c '✗ [a-zA-Z]' || true)"
if printf '%s' "$DIAG" | grep -q "opened a database successfully"; then ok "motor SQLite funcionando"; fi
if [[ "${FALTAN:-0}" -eq 0 ]]; then
  ok "bases de datos de Logos: $ENCONTRADAS encontradas"
else
  warn "bases de datos de Logos: $ENCONTRADAS encontradas, $FALTAN no (normal si Logos no ha sincronizado aún; ver: node $SERVIDOR/dist/cli.js)"
fi

# ---------------------------------------------------------------- final

echo
bold "═══ Listo ═══"
echo
if $MCP_OK; then
  ok "Reinicia Claude Code y pídele, por ejemplo: «busca comentarios en español sobre Romanos 8 en mi Logos»"
fi
echo
warn "Para que Claude pueda LEER el texto de los paneles de Logos hacen falta dos permisos de macOS"
warn "para la app desde la que corres Claude Code (Terminal, iTerm o Claude Desktop):"
info "Ajustes del Sistema → Privacidad y seguridad → Accesibilidad"
info "Ajustes del Sistema → Privacidad y seguridad → Grabación de pantalla"
info "Sin ellos, todo lo demás funciona (catálogo, notas, sermones, texto bíblico)."
echo
info "Para quitarlo todo: $DESTINO/desinstalar.sh"
echo
