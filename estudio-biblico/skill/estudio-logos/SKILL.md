---
name: estudio-logos
description: Busca, lee y estudia en Logos Bible Software por dos vías — la biblioteca en línea (Logos Web, app.logos.com, en el navegador integrado de Claude) y los datos personales en el Logos de escritorio (notas, resaltados, recortes, sermones, listas de pasajes, catálogo de libros con licencia) — y entrega lo encontrado con obra, página y enlace. La forma de estudiar no viene impuesta: cada persona la define en `configuracion.md` (pasos, cuándo entran los comentarios, si Claude guía con preguntas o lo hace todo, qué se entrega y dónde se guarda). Úsalo SIEMPRE que pidan "busca en Logos", "qué dice mi biblioteca sobre", "qué tengo en Logos de", "busca en mis notas", "qué he predicado sobre", "léeme lo que dice X sobre este pasaje", "vamos a estudiar la Biblia", "estudiemos Romanos 8", "estudio de tal pasaje o tema", o cuando quieran cambiar cómo estudian ("configura mi forma de estudiar").
---

# Estudiar en Logos (web + personal), a la manera de cada quien

Este skill hace dos cosas:

1. **Buscar y leer en Logos** con la cita exacta de dónde salió cada cosa (secciones 1-6). Esto es igual para todos.
2. **Estudiar como la persona estudia** (sección 7). Esto lo define ella en `configuracion.md`; el skill no trae un método propio.

## 0. Antes de todo: la configuración

1. Leer `configuracion.md` en esta carpeta.
2. Si no existe, o le falta la sección «Mi forma de estudiar» y la persona pide un estudio, correr la **puesta en marcha** (sección 9). Para una búsqueda simple basta con las cuentas y las preferencias.
3. Lo que diga la configuración manda sobre los valores por defecto de este archivo.
4. Tratar a la persona por su `nombre` y con el `tratamiento` (usted o tú) de la configuración.

## 1. Las dos vías

| Vía | Qué alcanza | Herramienta | ¿Toma el mouse? |
|---|---|---|---|
| **En línea** (Logos Web) | El **texto** de todos los libros con licencia de la cuenta que tenga la sesión abierta en `app.logos.com`: búsqueda en todos los libros, en uno solo, en la Biblia, por pasaje; y lectura completa de una sección | Navegador integrado (`mcp__Claude_Browser__*`) + `buscar-web.js` + `lector-web.js` | No |
| **Personal** (Logos de escritorio, por MCP) | Lo que **la persona escribió o guardó**: notas, resaltados, recortes, sermones del Sermon Builder, listas de pasajes, favoritos, planes de lectura; y el catálogo de su biblioteca con editorial y año para citar | Servidor MCP de Logos (`mcp__<servidor>__get_*`; el nombre está en la configuración, normalmente `logos`) | No: las herramientas `get_*` leen la base de datos local |

El escritorio **sí** toma el mouse con `open_*`, `navigate_passage`, `read_panel_text`, `read_resource_at`, `capture_panel_screenshot` y `search_all`. Esas quedan sujetas a `escritorio` en la configuración (por defecto: preguntar cada vez). Si están prohibidas y algo no abre en la web, se reporta como no leído; no se busca por otro lado. En Windows esas herramientas no existen: solo quedan las `get_*` y la web.

Si falta una vía (no hay servidor MCP, o no hay sesión web), se trabaja con la otra y se dice al principio de la respuesta cuál faltó y cómo activarla.

## 2. Qué se pide → qué se busca

| Pedido | Personal (MCP) | En línea (web) |
|---|---|---|
| Una palabra o un tema («justificación», «primicias») | `get_user_notes query`, `get_clippings`, `get_sermons query`, `get_passage_lists query` | Búsqueda en libros `kind=books` |
| Un pasaje («Romanos 8:28») | `get_user_notes passage`, `get_sermons query` con el libro, `get_passage_lists with_items` | Búsqueda en libros con la referencia como consulta + lo que diga cada recurso preferido en ese pasaje |
| Un recurso concreto («qué dice Moo de Romanos 8:28») | `get_library_catalog query` para el ID, editorial y año | Abrir el recurso en el pasaje y leer (sección 4) |
| «Lo mío» («mis notas sobre», «qué he predicado de») | Solo esta vía | — |
| «Qué libros tengo de» | `get_library_catalog` con `type`, `author`, `language`, `query` | — |

Las consultas de ambas vías se lanzan **en paralelo** cuando no dependen una de otra.

Las notas de Logos pueden ser estudios enteros de miles de palabras. Pedir `get_user_notes` con `limit` de 3 a 5; si la respuesta llega guardada en un archivo por ser larga, buscar ahí el término con `grep` y contexto en vez de leerla entera. De cada nota se reporta el ancla, la fecha, el título y el fragmento donde aparece lo buscado; la nota completa, solo si la piden.

## 3. Buscar en línea

1. Si la configuración trae `recursos_preferidos` y la pregunta es de interpretación, se busca **primero en esos** y después en todo, marcando cuál es cuál.
2. URL de búsqueda. `resources` va **siempre** explícito: si se omite, Logos Web reusa el filtro de la última búsqueda de esa cuenta y puede quedar limitada a un solo libro sin avisar.

   ```
   https://app.logos.com/search?q=<consulta URL-encoded>&kind=books&resources=allResources&syntax=v2&engine=lexical
   ```

   - En uno o varios libros: `resources=custom&resourceIds=LLS%3A<ID>` (varios separados por coma).
   - Solo en la Biblia: `kind=bible`. Factbook: `kind=factbook`.
   - Frase exacta: la consulta entre comillas (`%22primicias%22`). Los operadores de Logos (`AND`, `OR`, `NEAR`, `BEFORE`) funcionan dentro de `q`.
   - Referencia bíblica: en inglés (`Romans 8:28`); Logos la reconoce y busca por referencia.
   - `engine=lexical` fuerza la búsqueda precisa. La «Smart search» y el botón «Summarize» gastan créditos de IA de la cuenta y dan respuestas sin cita: no se usan.
3. `navigate` → `computer wait 8` → `javascript_tool` con el contenido entero de `buscar-web.js`. Devuelve hasta 60 resultados: `recurso` (ID), `seccion`, `extracto`, `cita` (empieza por el título de la obra y trae la página si la hay), `veces` y `abrir` (enlace al punto exacto).
4. Quitar lo que esté en `recursos_excluidos`. Agrupar por obra. Mostrar hasta `max_resultados`.
5. **Un extracto no es una lectura.** El extracto es un recorte de unas 30 palabras: sirve para decidir qué abrir, no para citar un argumento. Si piden qué dice un autor, se abre y se lee (sección 4).

## 4. Leer en línea

Procedimiento completo en `lector-web.md`. Resumen:

- Desde un resultado: `navigate` al enlace `abrir` → `wait 7`. Logos redirige a `app.logos.com/books/LLS%3A<ID>/articles/<artículo>`; ese enlace se guarda para la cita.
- En un pasaje: `https://ref.ly/logosres/LLS%3A<ID>?ref=Bible.Ro8.28` (abreviaturas en inglés). En una página: `?ref=page.N`.
- Inyectar `lector-web.js` y `window.logosChunk({ reset: true, stopRegex })`; saltar página por página con `?ref=page.<N+1>` hasta `stopped`; `window.logosTexto()` da el texto con `⟦Page N⟧` intercalado. Reinyectar el script después de cada `navigate`.
- Si la página pide iniciar sesión: **parar y avisar**. Nunca escribir credenciales.

Cuánto leer lo dice `profundidad_lectura` (`extracto`, `seccion` o `completo`). Una lectura larga (varios comentarios completos) conviene hacerla en un subagente que escriba el texto crudo en un archivo y devuelva solo un resumen, para no llenar la conversación.

## 5. Cómo se entrega una búsqueda

Dos bloques, siempre separados, porque no valen lo mismo:

```
## En su Logos (lo que usted escribió o guardó)
- Nota «<título>» — anclada a <pasaje>, <fecha>: <fragmento>
- Sermón «<título>» — predicado <fecha>, <lugar>
- Recorte de <obra>: «<texto>»

## En la biblioteca (Logos Web)
- <Obra>, <autor> (<editorial>, <año>), p. <N> — <qué dice, con su razón si se leyó> · [abrir](<enlace>)
  (Leído completo | Solo extracto de la búsqueda)
```

Reglas:
1. **Si no se leyó, no se afirma.** Lo que sale solo del extracto se marca «solo extracto». Nada de memoria: ni citas, ni griego, ni datos de un autor que no hayan salido de una herramienta en esta tarea.
2. **Cita completa.** Autor, obra, editorial y año salen de `get_library_catalog`; la página, de la última marca `⟦Page N⟧` antes del texto citado o de la `cita` del resultado. Sin página visible: «sin número de página visible». Formato según `estilo_cita`.
3. **Comillas solo para texto literal**, copiado exacto. La paráfrasis va sin comillas y con el autor nombrado.
4. **Enlaces que abren**: `app.logos.com/books/LLS%3A<ID>/articles/<artículo>` para la web. `ref.ly` abre el escritorio en la cuenta de quien hace clic.
5. Lo que no se pudo leer o no se encontró se dice al final, una línea por recurso, con el motivo.
6. Idioma de la respuesta: `idioma`. Los extractos quedan en su idioma original; si se traducen, se dice.

Si `guardar_en` tiene una carpeta, la búsqueda también se guarda como nota Markdown con frontmatter `tipo: busqueda-logos`, `consulta`, `fecha`, `fuentes` (lista de IDs).

## 6. Dos cuentas de Logos

Hay quien tiene dos (la propia y una prestada o institucional). En la configuración, cada cuenta dice su servidor MCP y si es la de la sesión web.
- Un recurso se declara «sin licencia» solo después de mirar el catálogo de **todas** las cuentas. Una portada con precio en la web no prueba nada: el libro puede estar en la otra cuenta.
- La web lee con la cuenta de la sesión abierta; un libro de la otra cuenta se lee en el escritorio (si está permitido) o se reporta como no leído.
- A una cuenta prestada se le dice por la etiqueta de la configuración, no por el nombre de su dueño.

## 7. Estudiar a la manera de la persona

Cuando piden un estudio («estudiemos Romanos 8:28-30», «vamos a estudiar la Biblia», «estudio del tema de la gracia»), se sigue **la sección «Mi forma de estudiar» de `configuracion.md`**, paso por paso y en su orden. Esa sección responde:

- **Para qué estudia** (predicar, dar una clase, crecer personalmente, investigar): cambia qué se busca y qué se entrega.
- **Los pasos**, en su orden, y qué fuentes van en cada uno.
- **Cuándo entran los comentarios**: desde el principio, o solo después de que la persona tenga su propia lectura del texto.
- **Quién hace qué**: Claude lo hace todo y entrega; Claude guía con preguntas y la persona responde; o una mezcla (qué pasos hace cada uno).
- **Qué se entrega**: resumen, bosquejo, estudio con notas al pie, fichas de citas, preguntas para un grupo; con las secciones que la persona quiere.
- **Dónde se guarda** y con qué nombre.

Reglas que valen para cualquier forma de estudiar:
1. Se hacen los pasos que la persona definió, no otros. Si un paso no se puede hacer (falta un recurso, no abre en la web), se dice y se sigue con el siguiente; no se reemplaza por algo que ella no pidió.
2. Si la forma de estudiar dice que Claude guía, **cada tarea es una sola cosa concreta** que se pueda empezar en dos minutos, con su pregunta del texto. No se le entrega la respuesta antes de que conteste; si pide «pista», se le acerca un paso, no se le resuelve.
3. Si dice que los comentarios van después, **nadie abre un comentario antes** de que la persona tenga su lectura escrita: ni ella ni Claude.
4. Las reglas de la sección 5 (no afirmar lo no leído, citas completas, comillas solo para lo literal) valen también dentro del estudio.
5. Cuando la persona corrija el método durante el trabajo («primero quiero las palabras», «no me hagas preguntas, hazlo tú», «agrega siempre la aplicación»), se actualiza «Mi forma de estudiar» en ese momento y se le dice qué cambió.

Si la persona no ha definido su forma de estudiar y pide un estudio, se le ofrecen los modelos de `formas-de-estudio.md` para empezar, eligiendo uno y ajustándolo (sección 9, pregunta 7). Los modelos son un punto de partida: lo que ella escriba después manda.

## 8. Lo que este skill no hace

- No escribe credenciales ni inicia sesión por nadie.
- No compra ni descarga recursos.
- No escribe en Logos (notas, resaltados): solo lee.
- No decide por la persona entre interpretaciones en disputa: presenta quién sostiene qué y con qué razón. Una conclusión propia de Claude va marcada como tal.

## 9. Puesta en marcha (primera vez)

Preguntar en tandas cortas (AskUserQuestion si está disponible) y escribir `configuracion.md` a partir de `configuracion.ejemplo.md`. Si el instalador ya dejó un `configuracion.md` con el nombre y la carpeta, completar lo que falte.

1. **Nombre y trato** (usted o tú).
2. **Vía en línea.** ¿Tiene cuenta de Logos? Abrir `https://app.logos.com` en el navegador integrado; que **la persona** inicie sesión. En Logos Web: *Settings → Accessibility → Enable limited view mode* (el lector depende de ese modo). Probar con una búsqueda.
3. **Vía personal.** ¿Tiene Logos de escritorio en esta computadora? Comprobar con `mcp__logos__diagnose`. Si el servidor no está, se instala con el paquete *Logos para Claude* (`github.com/prcontreras23/logos-para-claude`). Si tiene dos cuentas, un servidor por cuenta con nombres distintos.
4. Biblia por defecto, idioma de respuesta y de los recursos que prefiere.
5. ¿Se permite usar el escritorio cuando algo no abre en la web? (nunca / preguntar cada vez / sí).
6. Recursos preferidos y excluidos (opcional; se agregan después diciendo «prefiere tal comentario» o «no uses tal libro»).
7. **Su forma de estudiar**: mostrar los modelos de `formas-de-estudio.md` en una línea cada uno, preguntar cuál se parece más a como estudia, y después ajustar con él o ella paso por paso. Si prefiere describirla con sus palabras, se escribe tal como la dice, ordenada en pasos.
8. ¿Dónde guardar los estudios y las búsquedas?
