#!/bin/bash
# Instalador de doble clic para Mac.
#
# La persona no escribe ni un comando: hace doble clic, responde dos diálogos,
# y al final concede dos permisos en Ajustes del Sistema.

set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1
REPO_DIR="$(pwd)"

dialogo() {  # título, mensaje
  osascript -e "display dialog \"$2\" with title \"$1\" buttons {\"Continuar\"} default button 1 giving up after 900" >/dev/null 2>&1
}
preguntar() {  # título, mensaje -> 0 si sigue
  osascript -e "display dialog \"$2\" with title \"$1\" buttons {\"Cancelar\", \"Instalar\"} default button 2" >/dev/null 2>&1
}
avisar() {
  osascript -e "display dialog \"$2\" with title \"$1\" buttons {\"Entendido\"} default button 1 with icon caution" >/dev/null 2>&1
}
pedir_texto() {  # título, mensaje -> imprime "BOTON|texto" (vacío si cierra)
  osascript -e "set r to display dialog \"$2\" with title \"$1\" default answer \"\" buttons {\"Saltar\", \"Conseguir clave\", \"Guardar\"} default button 3" -e "return (button returned of r) & \"|\" & (text returned of r)" 2>/dev/null || true
}

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
morir() {
  echo; printf '\033[31m  ✗ %s\033[0m\n' "$*"
  avisar "No se pudo instalar" "$*"
  echo; echo "Puedes cerrar esta ventana."; exit 1
}

clear
cat <<'BANNER'

   Logos para Claude
   ──────────────────

   Vas a conectar tu biblioteca de Logos con Claude.
   No tienes que escribir nada: sigue los avisos que aparezcan.

BANNER

# ---------------------------------------------------------------- consentimiento

if ! preguntar "Logos para Claude" "Esto conecta tu Logos Bible Software con Claude Code, en esta computadora.

Qué va a poder hacer Claude:

• Buscar en tu catálogo y saber qué libros son tuyos.
• Abrir un comentario en un pasaje y leer su texto, con la cita.
• Leer tus notas, resaltados, recortes, sermones y planes de lectura.

Cómo funciona:

• Todo se lee de tu propia computadora. Nada se sube a ningún servidor.
• Para leer el texto de un libro, Claude mueve el mouse y copia del panel de Logos: durante esos segundos conviene no usar la Mac.
• Lo que sí sale hacia Claude es lo que tú le pidas leer en cada conversación.

La instalación toma unos 5 minutos.

¿Continuamos?"; then
  echo "Instalación cancelada."; exit 0
fi

# ---------------------------------------------------------------- clave opcional

MENSAJE_CLAVE="Las herramientas de texto bíblico por internet (get_bible_text, search_bible…) usan la API gratuita de Biblia.com. Es opcional: todo lo de Logos funciona sin ella.

Para conseguirla, en 2 minutos:
1. Dale a «Conseguir clave»: se abre api.biblia.com.
2. Entra con tu cuenta de Faithlife (la misma de Logos).
3. Crea una clave nueva. Si te pide una dirección web, pon: localhost
4. Copia la clave y pégala aquí.

Si prefieres hacerlo después: ~/logos-para-claude/clave-biblia.sh TU_CLAVE"

CLAVE=""
while :; do
  R="$(pedir_texto "Clave de Biblia API (opcional)" "$MENSAJE_CLAVE")"
  BOTON="${R%%|*}"; TEXTO="${R#*|}"
  case "$BOTON" in
    "Conseguir clave") open "https://api.biblia.com/v1/Users/SignIn"; sleep 1 ;;
    "Guardar") CLAVE="$(printf '%s' "$TEXTO" | tr -d '[:space:]')"; break ;;
    *) break ;;
  esac
done

# ---------------------------------------------------------------- instalar

ARGS=(--biblia RVR60)
[[ -n "$CLAVE" ]] && ARGS+=(--clave-biblia "$CLAVE")

chmod +x "$REPO_DIR/install.sh" 2>/dev/null
if ! "$REPO_DIR/install.sh" "${ARGS[@]}"; then
  morir "Algo falló durante la instalación. Revisa el texto de esta ventana para ver en qué paso."
fi

# ---------------------------------------------------------------- permisos

dialogo "Permisos de macOS" "Último paso. Para que Claude pueda leer el texto de los paneles de Logos, macOS necesita que autorices a la app desde la que usas Claude Code (Terminal, iTerm o Claude) en dos lugares:

1. Privacidad y seguridad → Accesibilidad
2. Privacidad y seguridad → Grabación de pantalla

Al darle a Continuar se abrirán esos dos paneles. Activa el interruptor de tu app en cada uno. Si tu app no aparece en la lista, agrégala con el botón +.

Sin estos permisos, todo lo demás funciona igual."

open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
sleep 2
open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"

# ---------------------------------------------------------------- final

dialogo "¡Listo!" "Tu biblioteca de Logos ya está conectada con Claude.

Cierra Claude Code y vuelve a abrirlo. Después pruébalo con algo como:

«¿Qué comentarios en español tengo sobre 1 Corintios?»
«Lee el Comentario Bíblico Adventista en Romanos 8:28»
«¿Qué sermones he predicado sobre la gracia?»

Abre Logos antes de pedirle que lea un libro."

echo
echo "Ya puedes cerrar esta ventana."
echo
