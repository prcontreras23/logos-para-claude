# CLAUDE.md — Esquema del vault «Estudios bíblicos»

> Este vault sigue el patrón **LLM Wiki** de Andrej Karpathy. En vez de buscar fragmentos desde cero en cada pregunta, Claude mantiene una wiki que se sintetiza y se actualiza con cada fuente y cada estudio nuevo. Este archivo es la capa 3: le dice a Claude cómo mantener la wiki. Se lee al inicio de cada sesión.
>
> El método de estudio por perícopas vive en el skill `estudio-biblico` (`~/.claude/skills/estudio-biblico/SKILL.md`). Los ajustes del estudiante (nombre, trato) están en `~/.claude/skills/estudio-biblico/ajustes.json`.

---

## 1. Las tres capas

```
CAPA 1 — FUENTES (las cura el estudiante; Claude no las reescribe)
  Biblicos/<NN Libro>/Cap NN/     ← cuadernos (su trabajo), notas de fuentes de Logos, estudios terminados
  Fuentes/                        ← lo que el estudiante trae: PDF, apuntes de clase, transcripciones,
                                    artículos, notas de un seminario. Se guarda tal cual.
  Sermones/Textos predícame.md    ← versículos que quiere predicar, con su idea inicial

CAPA 2 — WIKI (la escribe y mantiene Claude entera)
  wiki/index.md                   ← catálogo maestro: punto de entrada de toda consulta
  wiki/libros/<Libro>.md          ← síntesis de cada libro: propósito, estructura, perícopas estudiadas, hilo teológico
  wiki/temas/<Tema>.md            ← síntesis por tema a lo largo del canon (gracia, sábado, santuario, iglesia...)
  wiki/log.md                     ← bitácora cronológica, solo se agrega al final
  wiki/scripts/search-bm25.py     ← buscador por relevancia, sin dependencias

CAPA 3 — ESQUEMA
  CLAUDE.md (este archivo)        ← instrucciones de mantenimiento, no contenido
```

**Regla clave**: el estudiante casi nunca escribe la wiki. Claude la escribe y la mantiene; el estudiante cura las fuentes, dirige el análisis y hace las preguntas. Su trabajo propio (cuadernos, «Mi aplicación», sus ideas de sermón) se respeta tal cual y nunca se corrige ni se resume sin que lo pida.

Archivos de apoyo del método: `Biblicos/Mi progreso en el estudio bíblico.md` y, por libro, `00 - Índice de Perícopas.md`, `01 - Fuentes aprobadas.md` y `02 - Hilo teológico de <libro>.md`.

---

## 2. Operaciones

### INGEST (fuente nueva → integrarla en la wiki)

Cuando el estudiante trae un documento («guarda esto», «ingiere este PDF», «apuntes de la clase») o se termina un estudio de perícopa:

1. Leer la fuente completa. Si es un documento externo, guardarlo en `Fuentes/` con frontmatter `fuente: "<título o descripción> — <referencia>"` y `fuente_fecha: AAAA-MM-DD`.
2. Comentar con el estudiante los puntos clave, si aplica.
3. Actualizar las páginas de la wiki que toca: `wiki/libros/<Libro>.md` y las de `wiki/temas/` que correspondan. Una fuente puede tocar varias páginas. Crear la página si no existe.
4. Actualizar `wiki/index.md`.
5. Registrar en `wiki/log.md`: `## [AAAA-MM-DD] ingest | <qué> → <páginas tocadas>`.

### QUERY (responder desde la wiki, no desde cero)

1. Leer `wiki/index.md` para ubicar las páginas relevantes.
2. Profundizar solo en las que el índice confirma. Si no aparece nada claro, buscar con `python3 wiki/scripts/search-bm25.py "consulta" 5` (en Windows, `py` o `python` en vez de `python3`; si Python no está instalado, buscar con las herramientas de búsqueda de Claude).
3. Responder con wikilinks `[[página]]` y citas concretas.
4. **Si la respuesta tiene valor duradero** (una comparación, un análisis, una conclusión), archivarla como página nueva en `wiki/temas/` en vez de dejarla perdida en el chat. Así la exploración se acumula igual que un ingest.
5. Aplicar GROUNDING antes de afirmar cualquier cosa como hecho.

### GROUNDING (no inventar)

- Si una afirmación no tiene fuente clara (un estudio o nota de fuentes del vault, un recurso de Logos leído en la sesión, un documento de `Fuentes/`), no se presenta como hecho: se dice que no está verificado.
- Para lo delicado (doctrina disputada, un dato histórico discutido, una cita de Elena White) buscar al menos dos fuentes antes de tratarlo como firme.
- Mejor «no lo sé» o «no está en el vault» que inventar un versículo, una cita, una página o un dato.

### LINT (cuando el estudiante dice «revisa el wiki» o «lint»)

- Contradicciones entre páginas.
- Información que un estudio más nuevo ya superó.
- Páginas huérfanas (sin enlaces entrantes).
- Conceptos importantes mencionados sin página propia.
- Wikilinks rotos y enlaces bíblicos mal formados (reglas del skill).
- Vacíos que ameriten estudiar una perícopa o preguntarle al estudiante.

Registrar en `wiki/log.md`: `## [AAAA-MM-DD] lint | hallazgos`.

---

## 3. Convenciones

```yaml
tipo: estudio | cuaderno | fuentes | indice | sintesis | tema | nota
libro: 1 Corintios
pasaje: 1:10-17        # texto plano, sin enlaces
fecha: AAAA-MM-DD
actualizado: AAAA-MM-DD
```

- Carpetas de libro con su número canónico: `Biblicos/01 Génesis/`, `Biblicos/46 1 Corintios/`.
- Español con tildes y gramática correctas. Registro claro, sin frases de afiche ni lenguaje rebuscado. «Iglesia» es «iglesia».
- Toda referencia bíblica va enlazada a la LBLA en Logos, con las reglas del skill: `[1 Corintios 1:1-3](https://ref.ly/logosres/LLS:1.0.690?ref=BibleLBLA.1Co1.1-3)`. Nunca en el frontmatter ni en los encabezados.
- Los estudios y las páginas de la wiki se escriben para cualquier lector: no nombran al estudiante ni describen el proceso de trabajo.
