# Logos para Claude

Conecta tu biblioteca de **Logos Bible Software** con **Claude Code**, para que puedas pedirle cosas como *«¿qué comentarios en español tengo sobre 1 Corintios?»*, *«lee el Comentario Bíblico Adventista en Romanos 8:28 y cítamelo»* o *«¿qué sermones he predicado sobre la gracia?»*.

Funciona en **Mac** (completo) y en **Windows** (todo menos leer el texto de los paneles).

---

## Qué puede hacer Claude con esto

| | Herramientas | Qué hace |
|---|---|---|
| **Leer libros** | `read_resource_at`, `read_panel_text` | Abre un comentario, léxico o libro en un pasaje y devuelve su **texto**, con la cita que Logos adjunta (obra, editor, año, página). Solo Mac. |
| **Catálogo** | `get_library_catalog`, `get_resource_types` | Busca en tu biblioteca por tema, autor, tipo e idioma. Distingue lo que **tienes con licencia** de lo que Logos solo muestra para vender. |
| **Tus documentos** | `get_sermons`, `get_sermon`, `get_reading_plans`, `get_passage_lists` | Tus sermones del Sermon Builder en Markdown, tus planes de lectura con progreso, tus listas de pasajes. |
| **Tu estudio** | `get_user_notes`, `get_user_highlights`, `get_clippings`, `get_favorites`, `get_study_workflows` | Notas, resaltados, recortes, favoritos y flujos de trabajo. |
| **Texto bíblico** | `get_bible_text`, `search_bible`, `compare_passages`… | Por internet, vía la API gratuita de Biblia (RVR60 por defecto). Opcional. |
| **Navegar Logos** | `navigate_passage`, `open_resource`, `open_guide`, `open_factbook`, `search_all`… | Abre cosas en la pantalla de Logos. |

Acepta referencias **en español**: «Romanos 8:28», «1 Co 1:4-9», «Sal 23».

---

## Antes de instalar, lee esto

- **Todo se lee de tu computadora.** El catálogo, tus notas y tus sermones están en las bases de datos locales de Logos. Nada se sube a ningún servidor.
- **Lo que sí sale hacia Claude** es lo que tú le pidas en cada conversación: si le pides que lea un comentario, ese texto va a Claude para poder trabajarlo. Igual que cuando le pegas un párrafo.
- **Para leer el texto de un libro, Claude mueve el mouse.** Los archivos de Logos están cifrados, así que la única forma de sacar texto es la misma que usarías tú: seleccionar y copiar en el panel. Dura unos cinco segundos por pantalla; en ese momento conviene no usar la Mac. Por eso hacen falta dos permisos de macOS (ver abajo).
- **No modifica nada en Logos.** Solo lee.

---

## Qué necesitas

- Una Mac (o una PC con Windows 10/11 para la versión parcial)
- Logos Bible Software instalado y con tu biblioteca sincronizada
- Claude Code (si no lo tienes, el instalador lo instala)
- Unos 5 minutos

No necesitas saber programar. El instalador se encarga de lo demás: Node.js y, en Mac, las Command Line Tools de Apple. Usa Homebrew si lo tienes; si no, baja los instaladores oficiales y los deja en tu carpeta de usuario, **sin pedir contraseña de administrador**.

---

## Instalar

### Mac: una línea en la Terminal

```bash
curl -fsSL https://raw.githubusercontent.com/prcontreras23/logos-para-claude/main/instalar.sh | bash
```

Baja el proyecto y arranca el instalador. Verás dos diálogos: uno de consentimiento y otro que pide, opcional, la clave de Biblia API (ver abajo cómo conseguirla; si no la quieres, dale a Saltar). Al final se abren los dos paneles de permisos de macOS.

### Mac: doble clic

Descarga el proyecto (botón verde **Code → Download ZIP**), descomprime, y haz doble clic en **`Instalar en Mac.command`**. Si macOS se niega a abrirlo porque «viene de internet», usa la línea de arriba: lo que baja `curl` no lleva esa marca.

### Windows: una línea en PowerShell

```powershell
irm https://raw.githubusercontent.com/prcontreras23/logos-para-claude/main/instalar-windows.ps1 | iex
```

O descarga el ZIP y haz doble clic en **`Instalar en Windows.bat`**. En Windows no están las herramientas de lectura de paneles ni las capturas (usan APIs de macOS); catálogo, notas, sermones y planes funcionan igual.

### Después de instalar

1. **Reinicia Claude Code** (cierra la sesión y ábrela de nuevo). El servidor `logos` aparece con 30 herramientas.
2. **Abre Logos** antes de pedirle a Claude que lea un libro.
3. Pruébalo: *«¿Qué comentarios en español tengo sobre 1 Corintios?»* y luego *«Lee el primero en 1 Corintios 1:4, tres pantallas»*.

---

## Clave de Biblia API (opcional)

Las herramientas de **texto bíblico por internet** (`get_bible_text`, `search_bible`, `get_passage_context`, `compare_passages`, `scan_references`) usan la API gratuita de [Biblia.com](https://bibliaapi.com/docs/), de la misma casa que Logos. Sin clave quedan apagadas y **todo lo demás funciona igual**: catálogo, lectura de paneles, notas, sermones.

Para conseguirla, unos 2 minutos:

1. Entra en <https://api.biblia.com/v1/Users/SignIn> con tu **cuenta de Faithlife**, la misma con la que abres Logos.
2. Crea una clave nueva. Si te pide un nombre y una dirección web para la aplicación, pon el nombre que quieras y `localhost` (es para uso en tu computadora; las claves se limitan al sitio que declares y `localhost` está permitido).
3. Copia la clave.

Dónde ponerla:

- **Durante la instalación**, en el diálogo que la pide (el botón **Conseguir clave** te abre el sitio).
- **Después**, sin reinstalar: `~/logos-para-claude/clave-biblia.sh TU_CLAVE` en Mac, o `.\install.ps1 -ClaveBiblia TU_CLAVE` en Windows. Reinicia Claude Code.

La API sirve las Biblias RVR60 y RVA en español, además de LEB, KJV, ASV y otras en inglés; las versiones con licencia (NVI, LBLA, RVR95) no están disponibles por esta vía. Para leer esas, Claude abre tu Biblia en Logos y lee el panel.

---

## Permisos de macOS (solo para leer paneles)

Para seleccionar y copiar en Logos, macOS exige que la app desde la que corres Claude Code (Terminal, iTerm o la app Claude) esté autorizada en:

- **Ajustes del Sistema → Privacidad y seguridad → Accesibilidad**
- **Ajustes del Sistema → Privacidad y seguridad → Grabación de pantalla**

El instalador abre ambos paneles al final. Si tu app no está en la lista, agrégala con el botón **+**. Sin estos permisos, todo lo demás funciona; solo `read_panel_text`, `read_resource_at` y `capture_panel_screenshot` devuelven un error explicando qué falta.

---

## Ajustes

Se pasan como variables de entorno al servidor (`claude mcp add … --env NOMBRE=valor`, o en el bloque `env` de `~/.claude.json`):

| Variable | Para qué | Por defecto |
|---|---|---|
| `LOGOS_DEFAULT_BIBLE` | Biblia de las herramientas de texto por internet (`RVR60`, `RVA`, `LEB`, `KJV`…) | `RVR60` |
| `BIBLIA_API_KEY` | Clave gratuita de bibliaapi.com. Sin ella, esas herramientas quedan apagadas; todo lo de Logos funciona | vacío |
| `LOGOS_DATA_DIR`, `LOGOS_CATALOG_DIR` | Rutas del perfil de Logos, si la detección automática falla | detectado |
| `LOGOS_PANEL_TEXT_OFFSETS` | Geometría del panel, `arriba,izquierda,derecha,abajo` en píxeles, si una actualización de Logos mueve la barra de herramientas | `165,20,40,10` |
| `LOGOS_DEBUG` | `1` para ver en stderr el rectángulo que se selecciona en cada lectura | vacío |

---

## Problemas frecuentes

**«Clipboard came back empty»** al leer un panel: la ventana de Logos está tapada por otra, o faltan los permisos de Accesibilidad. Destapa Logos, revisa los permisos y repite.

**Las lecturas salen vacías o empiezan con texto de la barra de herramientas** tras actualizar Logos: cambió la geometría del panel. Corre una lectura con `LOGOS_DEBUG=1`, mira el rectángulo, y ajusta `LOGOS_PANEL_TEXT_OFFSETS`.

**«Database not found»**: Logos no ha creado su catálogo todavía. Abre Logos, deja que sincronice la biblioteca, y vuelve a intentar. Si tus datos están en una ruta rara, fija `LOGOS_DATA_DIR` y `LOGOS_CATALOG_DIR`.

**«better_sqlite3 … NODE_MODULE_VERSION»** después de actualizar Node: `cd ~/logos-para-claude/logos-mcp-server && npm rebuild better-sqlite3`.

**Diagnóstico completo**: `node ~/logos-para-claude/logos-mcp-server/dist/cli.js`, o pídele a Claude que corra la herramienta `diagnose`.

**Homebrew roto o que no quieres usar**: `LOGOS_SIN_BREW=1 ./install.sh` obliga al instalador a usar los instaladores oficiales (Node en `~/.local/node`).

---

## Desinstalar

Mac: `~/logos-para-claude/desinstalar.sh` · Windows: `%USERPROFILE%\logos-para-claude\desinstalar.ps1`

Quita el registro en Claude Code y Claude Desktop y borra la carpeta. No toca Logos ni sus datos.

---

## De dónde viene

El servidor MCP es el proyecto [LogosBibleSoftwareMCP](https://github.com/robrawks/LogosBibleSoftwareMCP) de Rob Pecoraro (MIT), con las mejoras de este fork ([PR #12](https://github.com/robrawks/LogosBibleSoftwareMCP/pull/12)): lectura de texto de los paneles, referencias en español, catálogo con licencia e idioma, sermones y planes de lectura, y tres correcciones. La carpeta `logos-mcp-server/` de este repo es una copia de [ese fork](https://github.com/prcontreras23/LogosBibleSoftwareMCP) para que el instalador sea autocontenido (`sync-servidor.sh` la actualiza).

Hecho por Francis Contreras, pastor adventista en República Dominicana, para leer su biblioteca desde Claude. Si te sirve, úsalo; si encuentras un fallo, abre un issue.
