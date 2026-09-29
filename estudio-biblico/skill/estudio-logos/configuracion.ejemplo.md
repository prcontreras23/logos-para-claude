# Configuración de estudio-logos

> El skill lee este archivo antes de cada búsqueda o estudio. El instalador lo copia como `configuracion.md` y le pone el nombre y la carpeta; lo demás se completa la primera vez que se usa, o diciéndole a Claude «configura mi forma de estudiar». Se puede editar a mano.

## Persona

- **nombre**:
- **tratamiento**: usted    <!-- usted | tú -->

## Cuentas

Una fila por cuenta de Logos. `servidor_mcp` es el nombre con que se registró el servidor MCP de esa cuenta (el instalador lo registra como `logos`). `web: sí` en la cuenta que tiene la sesión abierta en app.logos.com. Dejar `servidor_mcp` vacío si esa cuenta no tiene Logos de escritorio en esta computadora.

| etiqueta | servidor_mcp | web | notas |
|---|---|---|---|
| Mi cuenta | logos | sí | |

## Preferencias

- **idioma**: es
- **idioma_recursos**: es, en    <!-- en qué orden preferir los recursos -->
- **biblia_por_defecto**: RVR60
- **escritorio**: preguntar    <!-- nunca | preguntar | sí — el Logos de escritorio toma el mouse unos segundos -->
- **profundidad_lectura**: seccion    <!-- extracto | seccion | completo -->
- **max_resultados**: 15
- **estilo_cita**: Autor, *Obra* (Editorial, año), p. N    <!-- o «el de Logos», que respeta el estilo configurado en Logos -->
- **guardar_en**:    <!-- carpeta donde se guardan estudios y búsquedas; vacío = solo en el chat -->

## Recursos preferidos

Se buscan primero cuando la pregunta es de interpretación. El ID (`LLS:...`) sale en `get_library_catalog`.

| Recurso | ID | Para qué |
|---|---|---|

## Recursos excluidos

Nunca se citan. ID o una descripción («devocionales», «homilética del siglo XIX»).

-

## Mi forma de estudiar

Vacía hasta la primera vez que se pida un estudio. Modelos para empezar en `formas-de-estudio.md`.

- **Para qué estudio**:
- **Pasos**:
  1.
- **Comentarios**:    <!-- desde el principio | después de tener mi propia lectura -->
- **Quién hace qué**:    <!-- Claude lo hace todo | Claude me guía con preguntas | mezcla: qué pasos hago yo -->
- **Qué me entrega**:
- **Dónde se guarda y con qué nombre**:
