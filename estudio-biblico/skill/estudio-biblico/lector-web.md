# Leer un recurso de Logos por la web sin tocar el mouse

Procedimiento verificado el 2026-09-06 con Thiselton (NIGTC, `LLS:29.51.13`) y los Padres (ACCS, `LLS:ACCSREVNT07`). Lo usa el agente `lector-fuentes-logos`; el hilo principal no lee.

## Qué hace falta

- Navegador integrado de Claude (`mcp__Claude_Browser__*`, en la app de Claude, pestaña Code), con la sesión del estudiante ya iniciada en `app.logos.com`. Si pide sesión, **parar y reportar**; nunca tocar credenciales.
- Ajuste de Logos Web: *Settings → Accessibility → Enable limited view mode*.
- El archivo `lector-web.js` (en esta misma carpeta, `~/.claude/skills/estudio-biblico/`), que se inyecta con `javascript_tool` **después de cada `navigate`** (cada navegación recarga la app y borra `window`; el texto acumulado sobrevive porque el script lo guarda en `sessionStorage` de la pestaña).
- **No hace falta que el panel del navegador esté visible** si se lee por saltos (modo B). El desplazamiento (modo A) sí lo exige.

## URL del recurso

Siempre con el prefijo `LLS%3A` delante del ID, tenga letras o números:

- En un pasaje: `https://ref.ly/logosres/LLS%3A29.51.13?ref=Bible.1Co1.4` (abreviaturas inglesas: `1Co`, `Ro`, `Ge`, `Ps`, `Isa`; rango `Bible.1Co1.4-9`).
- En una página del libro: `https://ref.ly/logosres/LLS%3A29.51.13?ref=page.90`.
- Léxico por palabra: `https://ref.ly/logosres/LLS%3A<ID>?hw=<griego URL-encoded>`.

Sin el prefijo, los IDs numéricos (`29.51.13`) devuelven «we couldn't find that resource».

Después de `navigate`, esperar **6 segundos** (`computer wait 6`) antes de leer: la pestaña dice «Logos Free Edition» mientras carga y pasa a «Legacy Edition» cuando está lista.

## Cómo está hecho el panel (y por qué el procedimiento es así)

El contenedor `.resourceViewer_LHCJb` es un desplazador virtual de **todo el libro**: el DOM solo contiene unos 30 párrafos alrededor de la posición actual (unos 5.000 caracteres). Los cambios de página vienen como `<span rel="milestone" data-datatype="page" data-reference="Page 89">`. Al navegar a un pasaje, el panel suele caer en la **bibliografía** de la sección (Thiselton) o justo antes del versículo: hay que seguir leyendo hasta el encabezado que interesa.

Dos comportamientos que mandan:

1. **Cambiar `scrollTop` solo redibuja si la pestaña está visible.** Con el panel del navegador oculto (`document.hidden = true`), el desplazamiento no avanza y el texto se queda en la primera pantalla. Esto fue lo que en v4 se registró como «la web no paginó».
2. **Navegar por URL sí redibuja aunque esté oculto.** Cada `?ref=page.N` o `?ref=Bible.…` trae un bloque nuevo de ~5.000 caracteres.

## Modo B — saltos por página (funciona con el panel oculto; usar por defecto)

1. `navigate` a `?ref=Bible.<inicio de la perícopa>` → `wait 6`.
2. Inyectar `lector-web.js` (`javascript_tool` con el contenido del archivo) y, en la misma llamada, `window.logosChunk({ reset: true, stopRegex: '^1:10' })`.
3. Leer la respuesta — el `stopRegex` es el encabezado de la **siguiente** perícopa tal como lo escribe ese comentario (mirar `encabezados` en la respuesta para ver el formato: `1:4–9`, `1:10`, `1:10-17`, etc.). Devuelve `paginaActual`.
4. Mientras `stopped` sea `false`: `navigate` a `?ref=page.<paginaActual + 1>` (**de una página en una**: saltando de dos en dos se perdió la página 95 de Thiselton, porque el bloque dibujado alrededor de la 96 empezaba después de su marca) → `wait 5` → `javascript_tool`: **contenido de `lector-web.js` seguido de** `window.logosChunk({ stopRegex: '^1:10' })` (una sola llamada). Conviene meter varias páginas en un solo `browser_batch` (navigate, wait, javascript × N) y leer `stopped` al final. Cada bloque nuevo se acumula sin repetir; `nuevos` dice cuántos párrafos aportó. Si `nuevos` es 0 dos veces seguidas, saltar dos páginas.
5. Al parar, `javascript_tool`: inyectar el script y `window.logosTexto()` → ese es el texto para la nota de fuentes, con `⟦Page N⟧` intercalado donde cambia la página. Antes de empezar otro recurso en la misma pestaña, `logosChunk({ reset: true })` borra lo acumulado.

La casilla de referencia del panel está **deshabilitada** en modo de vista limitada, así que no hay salto dentro de la app sin recargar: cada página es una recarga (~6 s).

Costo medido (2026-09-06, panel oculto): 7 saltos de Thiselton, páginas 88-100, **31.000 caracteres en 41 segundos**, unos 6 s por salto incluyendo la recarga. Una sección de 15 páginas ronda el minuto y medio. Sin mouse, sin bloquear la Mac, sin que el panel del navegador esté a la vista.

Si el recurso **no tiene marcadores de página** (`paginaActual` queda `null`), saltar por versículo: `?ref=Bible.1Co1.5`, `1Co1.6`, … hasta el `stopRegex`.

## Modo A — desplazamiento (solo si el panel del navegador está visible)

Después de los pasos 1-3: `javascript_tool`: `await window.logosScroll({ stopRegex: '^1:10', steps: 8 })`, repetir hasta `stopped`. Más rápido (medio segundo por pantalla), pero si `document.hidden` es `true` la función se niega y remite al modo B.

## Cómo citar

- **Página**: la última marca `⟦Page N⟧` anterior al párrafo citado. Si el bloque no trae marca, es la `paginaActual` del bloque anterior (las páginas son contiguas al saltar por página).
- **Obra, autor, editorial, año**: `get_library_catalog query="<título>"` devuelve editorial y año (`mcp__logos__get_library_catalog`, la misma cuenta del estudiante que está abierta en la web). El botón «Info» de la web solo da la reseña editorial, no sirve para citar.
- Título repetido: Barrett (Continuum 1968) y Thiselton (Eerdmans 2000) se llaman igual; distinguir por autor y año.

## Cómo elegir el `stopRegex`

Mirar las líneas cortas del texto acumulado (encabezados) para ver cómo numera cada obra; la respuesta de `logosChunk` trae `encabezados`, y `logosTexto()` permite filtrar líneas de menos de 70 caracteres. Formatos vistos el 2026-09-06:

| Obra | Cómo encabeza | `stopRegex` para parar antes de 1:10 |
|---|---|---|
| Thiselton (NIGTC) | Secciones numeradas con el rango entre paréntesis: `2. Paul's Thanksgiving: The Eschatological Focus (1:7–9)`; dentro, cada versículo empieza con el número solo: `5 Several issues of translation…`, `7 The grammatical construction…`. Antes de cada sección hay una bibliografía larga | `\(1:10[–-]` |
| ACCS (Padres) | `1:4–9 THANKSGIVING`, luego `1:4a Thanking God for Them`, `1:5 Enriched with Speech and Knowledge` | `^1:10` |

Si el `stopRegex` no aparece tras muchas páginas, revisar el formato antes de seguir saltando: el texto puede estar ya en la sección siguiente con otro encabezado.

## Verificaciones antes de transcribir

- Que `encabezados` muestre el versículo pedido: si el bloque es bibliografía o la voz equivocada de un diccionario, seguir saltando, no transcribir.
- Que el título de la pestaña sea el recurso pedido (`NIGTC 1Co`, `ACCS 1-2 Co`, …).
- Un `nuevos: 0` repetido = el panel no avanzó; cambiar de página o de versículo, no insistir.

## Cuándo caer al escritorio (`mcp__logos__read_resource_at`)

Solo si el recurso no abre en la web o si no hay navegador integrado, y siempre con permiso del estudiante pedido en el momento. El escritorio secuestra el mouse; la web no. Reglas: `panel` explícito (normalmente `right`), recurso descargado, y cotejar la línea `Citation —` antes de usar el texto.

## Capturar el enlace de la cita (2026-09-08)

Tras cada `navigate` a una URL de ref.ly, leer `location.href`: Logos Web redirige a `https://app.logos.com/books/LLS%3A<ID>/articles/<id>`. Ese `<id>` (p. ej. `P...138`, `COMM.CH2.2.2`, `COMM.1.5`) se anota en el crudo junto a la marca `⟦Page N⟧` del bloque, porque es la única URL que abre Logos Web posicionada (ref.ly, con la app de escritorio instalada, abre la app en vez de la web). Es por sección, no por página. No intentar `&off=` ni `/references/page.N`: probados y descartados, posicionan mal o redirigen a otra sección.
