#!/bin/bash
# Instalación de lo que hace falta para Logos para Claude en macOS:
# Node.js 20+, las Command Line Tools de Xcode (clang y swiftc, para leer el
# texto de los paneles) y Claude Code.
#
# No depende de Homebrew: lo usa si está y funciona, pero si no, cae a los
# instaladores oficiales, que se extraen dentro de la carpeta del usuario y no
# piden contraseña de administrador.
#
# Lo cargan install.sh e "Instalar en Mac.command".

ruta_extendida() {
  local extra=(
    "$HOME/.local/bin"
    "$HOME/.local/node/bin"
    "/opt/homebrew/bin"
    "/usr/local/bin"
  )
  local d
  for d in "${extra[@]}"; do
    [[ -d "$d" && ":$PATH:" != *":$d:"* ]] && PATH="$d:$PATH"
  done
  export PATH
}

tiene() { command -v "$1" >/dev/null 2>&1; }

cargar_brew() {
  tiene brew && return 0
  local b
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$b" ]]; then
      eval "$("$b" shellenv)" 2>/dev/null
      return 0
    fi
  done
  return 1
}

_probar_brew() {
  cargar_brew || return 1
  brew install "$1" >/dev/null 2>&1 || return 1
  ruta_extendida
  return 0
}

# ------------------------------------------------------------------ Node.js

# El servidor exige Node 20 o más nuevo (better-sqlite3 12 ya no soporta 18).
node_sirve() {
  tiene node || return 1
  local v; v="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null)"
  [[ "${v:-0}" -ge 20 ]]
}

instalar_node() {
  ruta_extendida
  node_sirve && return 0

  _probar_brew node && { node_sirve && return 0; }

  # Tarball oficial de nodejs.org (última LTS), extraído en ~/.local/node.
  # index.tab es una tabla separada por tabuladores; la columna 10 es "lts"
  # ("-" cuando la versión no es LTS). Se evita python3 a propósito: en una
  # Mac sin Command Line Tools, /usr/bin/python3 dispara su instalador.
  local arch version url tmp
  arch="$(uname -m)"; [[ "$arch" == "arm64" ]] && arch="arm64" || arch="x64"
  version="$(curl -fsSL --max-time 30 https://nodejs.org/dist/index.tab 2>/dev/null | awk -F'\t' 'NR>1 && $10!="-" {print $1; exit}')"
  [[ -z "$version" ]] && return 1
  url="https://nodejs.org/dist/$version/node-$version-darwin-$arch.tar.gz"
  tmp="$(mktemp -d)"
  curl -fsSL --max-time 600 "$url" -o "$tmp/node.tgz" 2>/dev/null || { rm -rf "$tmp"; return 1; }
  rm -rf "$HOME/.local/node"; mkdir -p "$HOME/.local/node"
  tar -xzf "$tmp/node.tgz" -C "$HOME/.local/node" --strip-components=1 || { rm -rf "$tmp"; return 1; }
  rm -rf "$tmp"
  ruta_extendida
  node_sirve
}

# ------------------------------------------------------------------ Command Line Tools

# clang compila el ayudante que localiza las ventanas de Logos; swiftc, el que
# arrastra el mouse para seleccionar texto. Ambos vienen con las Command Line
# Tools. Instalarlas abre un diálogo del sistema que la persona debe aceptar.
tiene_clt() { xcode-select -p >/dev/null 2>&1 && tiene clang && tiene swiftc; }

instalar_clt() {
  tiene_clt && return 0
  printf '\033[33m  ! Faltan las Command Line Tools de Apple. Se va a abrir una ventana de macOS.\033[0m\n'
  printf '\033[33m  ! Dale a "Instalar" y espera a que termine (varios minutos).\033[0m\n'
  xcode-select --install >/dev/null 2>&1
  local i
  for i in $(seq 1 240); do   # hasta 20 minutos
    tiene_clt && return 0
    sleep 5
  done
  tiene_clt
}

# ------------------------------------------------------------------ Claude Code

instalar_claude() {
  ruta_extendida
  tiene claude && return 0
  curl -fsSL https://claude.ai/install.sh 2>/dev/null | bash >/dev/null 2>&1
  ruta_extendida
  tiene claude
}

# ------------------------------------------------------------------ Logos

tiene_logos() { [[ -d "/Applications/Logos.app" || -d "$HOME/Applications/Logos.app" ]]; }

# Carpeta de datos del perfil de Logos que tiene el catálogo de la biblioteca.
# Devuelve el id del perfil (p. ej. pzuaw3le.yri) o nada.
perfil_logos() {
  local base="$HOME/Library/Application Support/Logos4"
  local d
  for d in "$base"/Data/*/LibraryCatalog/catalog.db; do
    [[ -f "$d" ]] && { basename "$(dirname "$(dirname "$d")")"; return 0; }
  done
  return 1
}

# ------------------------------------------------------------------ PATH persistente

persistir_ruta() {
  local rc="$HOME/.zshrc"
  [[ "${SHELL:-}" == *bash* ]] && rc="$HOME/.bash_profile"
  local linea='export PATH="$HOME/.local/bin:$HOME/.local/node/bin:$PATH"'
  grep -qsF '.local/node/bin' "$rc" || echo "$linea" >> "$rc"
}
