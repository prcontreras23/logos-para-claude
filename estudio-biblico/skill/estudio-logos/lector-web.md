# Leer un recurso de Logos por la web sin tocar el mouse

Procedimiento probado en Logos Web (`app.logos.com`) con comentarios, diccionarios, léxicos y Padres de la Iglesia. Funciona con cualquier recurso de la cuenta que tenga la sesión abierta.

## Qué hace falta

- Navegador integrado de Claude (`mcp__Claude_Browser__*`) con la sesión de Logos ya iniciada **por la persona**. Si pide sesión, parar y avisar; nunca escribir credenciales.
- En Logos Web: *Settings → Accessibility → Enable limited view mode*. El lector depende de ese modo.
- `lector-web.js` (en esta carpeta), que se inyecta con `javascript_tool` **después de cada `navigate`**: cada navegación recarga la app y borra `window`. El texto acumulado sobrevive porque el script lo guarda en `sessionStorage` de la pestaña.
- El panel del navegador **no necesita estar a la vista** si se lee por saltos (modo B).

## URL del recurso

Siempre con el prefijo `LLS%3A` delante del ID:

- En un pasaje: `https://ref.ly/logosres/LLS%3A<ID>?ref=Bible.Ro8.28` (abreviaturas en inglés: `Ge`, `Ex`, `Ps`, `Isa`, `Mt`, `Jn`, `Ro`, `1Co`, `Heb`, `Re`; rango `Bible.Ro8.28-30`).
- En una página: `https://ref.ly/logosres/LLS%3A<ID>?ref=page.90`.
- Léxico por palabra: `https://ref.ly/logosres/LLS%3A<ID>?hw=<palabra URL-encoded>`.
- Desde un resultado de búsqueda: el enlace `abrir` que devuelve `buscar-web.js` (`app.logos.com/books/LLS%3A<ID>/offsets/<n>`), que cae en el punto exacto del resultado.

Sin el prefijo `LLS%3A`, los IDs numéricos (`29.51.13`) dan «we couldn't find that resource».

Después de `navigate`, esperar **6-7 segundos** (`computer wait 7`). Mientras carga, la pestaña dice «Logos Free Edition»; cuando está lista, muestra el nombre del plan de la cuenta.

## Cómo está hecho el panel

El contenedor `.resourceViewer_LHCJb` es un desplazador virtual de **todo el libro**: el DOM solo tiene unos 30 párrafos alrededor de la posición actual (unos 5.000 caracteres). Los cambios de página vienen como `<span rel="milestone" data-datatype="page" data-reference="Page 89">`. Al abrir un pasaje, el panel a veces cae en la bibliografía de la sección o justo antes del versículo: hay que seguir hasta el encabezado que interesa.

Dos comportamientos que mandan:

1. **Cambiar `scrollTop` solo redibuja si la pestaña está visible.** Con el panel oculto (`document.hidden = true`) el desplazamiento no avanza.
2. **Navegar por URL sí redibuja aunque esté oculto.** Cada `?ref=page.N` o `?ref=Bible.…` trae un bloque nuevo.

## Modo B — saltos por página (usar por defecto)

1. `navigate` al recurso en el pasaje o en el resultado → `wait 7`.
2. `javascript_tool` con el contenido de `lector-web.js` seguido de `window.logosChunk({ reset: true, stopRegex: '<encabezado de la sección siguiente>' })`.
3. Leer la respuesta: `encabezados` muestra cómo numera ese libro sus secciones, para ajustar el `stopRegex`. Devuelve `paginaActual`.
4. Mientras `stopped` sea `false`: `navigate` a `?ref=page.<paginaActual + 1>` → `wait 5` → `javascript_tool`: contenido de `lector-web.js` + `window.logosChunk({ stopRegex })`. **De una página en una**: saltando de dos en dos se pierden páginas. Conviene meter varias en un solo `browser_batch` y mirar `stopped` al final. Si `nuevos` es 0 dos veces seguidas, saltar dos páginas.
5. Al parar: `javascript_tool` con el script + `window.logosTexto()` → texto con `⟦Page N⟧` intercalado. Antes de empezar otro recurso en la misma pestaña, `logosChunk({ reset: true })`.

Costo medido: unos 6 segundos por página; una sección de 15 páginas, cerca de minuto y medio.

Si el recurso **no tiene marcas de página** (`paginaActual` queda `null`), saltar por versículo: `?ref=Bible.Ro8.29`, `Ro8.30`, … hasta el `stopRegex`.

## Modo A — desplazamiento (solo con el panel visible)

Después de los pasos 1-3: `await window.logosScroll({ stopRegex, steps: 8 })`, repetir hasta `stopped`. Es más rápido, pero si la pestaña está oculta la función se niega y remite al modo B.

## Cómo elegir el `stopRegex`

Cada obra numera distinto. Mirar `encabezados` en la respuesta o las líneas cortas de `logosTexto()`. Ejemplos vistos:

| Estilo de la obra | Ejemplo de encabezado | `stopRegex` para parar antes de 1:10 |
|---|---|---|
| Rango entre paréntesis | `Paul's Thanksgiving (1:7–9)` | `\(1:10[–-]` |
| Rango al inicio | `1:10–17 DIVISIONS` | `^1:10` |
| Versículo solo, al inicio del párrafo | `10 Now I exhort you…` | `^10 ` |

Si el `stopRegex` no aparece tras muchas páginas, revisar el formato: puede que el texto ya esté en la sección siguiente con otro encabezado.

## Cómo citar

- **Página**: la última marca `⟦Page N⟧` antes del párrafo citado. Si el bloque no trae marca, la `paginaActual` del bloque anterior.
- **Autor, obra, editorial, año**: `mcp__<servidor>__get_library_catalog query="<título>"` de la cuenta dueña del libro. El botón «Info» de la web solo trae la reseña editorial.
- **Enlace**: después de cada `navigate`, leer `location.href`. Logos Web redirige a `https://app.logos.com/books/LLS%3A<ID>/articles/<id>`; ese es el enlace que abre el libro en esa sección. Es por sección, no por página.
- Títulos repetidos (dos comentarios con el mismo nombre): distinguir por autor y año.

## Verificaciones antes de transcribir

- Que `encabezados` muestre la sección pedida; si es bibliografía o la voz equivocada de un diccionario, seguir saltando.
- Que el título de la pestaña sea el recurso pedido.
- Un `nuevos: 0` repetido = el panel no avanzó; cambiar de página o de versículo, no insistir.

## Cuándo caer al escritorio

Solo si el recurso no abre en la web y la configuración lo permite (`escritorio: sí`, o `preguntar` y la persona dijo que sí en ese momento): `mcp__<servidor>__read_resource_at`. El escritorio toma el mouse y el teclado unos segundos; la ventana de Logos tiene que estar a la vista.
