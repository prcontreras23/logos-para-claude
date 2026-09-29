// Lector de paneles de Logos Web (app.logos.com) para el navegador integrado de Claude.
// Pegar ENTERO en mcp__Claude_Browser__javascript_tool una vez por pestaña; define
// window.logosChunk, window.logosScroll y window.logosTexto. Ver lector-web.md.
//
// Por qué así (verificado 2026-09-06):
// - El panel `.resourceViewer_LHCJb` es un desplazador virtual de TODO el libro: el DOM
//   solo contiene ~30 párrafos alrededor de la posición actual.
// - Cambiar scrollTop solo redibuja si la pestaña está visible (document.hidden = false);
//   con el panel del navegador oculto, el desplazamiento no avanza. La navegación por URL
//   (?ref=page.N o ?ref=Bible.1Co1.7) sí redibuja aunque esté oculto.
// - Los cambios de página vienen como <span rel="milestone" data-datatype="page"
//   data-reference="Page 89">: se insertan como ⟦Page 89⟧ para poder citar.
// - textContent, no innerText: innerText fuerza el diseño y con el panel oculto se cuelga.

// El estado vive en sessionStorage (misma pestaña, mismo origen app.logos.com) porque cada
// navigate recarga la app y borra `window`. Este archivo hay que volver a inyectarlo tras
// cada navigate; el texto acumulado se conserva.
const __KEY = 'logosLector';
function __load() {
  try { const j = JSON.parse(sessionStorage.getItem(__KEY) || 'null'); if (j) return { seen: new Set(j.out), out: j.out, page: j.page }; } catch {}
  return { seen: new Set(), out: [], page: null };
}
function __save(L) { sessionStorage.setItem(__KEY, JSON.stringify({ out: L.out, page: L.page })); }
window.__logosLector = __load();

// Recoge lo que hay dibujado ahora en el panel y lo acumula sin repetir.
// Devuelve un resumen; el texto completo acumulado se pide con logosTexto().
window.logosChunk = function ({ reset = false, stopRegex = null } = {}) {
  const el = document.querySelector('.resourceViewer_LHCJb');
  if (!el) return { error: 'no hay panel de recurso en esta pestaña' };
  if (reset) { window.__logosLector = { seen: new Set(), out: [], page: null }; sessionStorage.removeItem(__KEY); }
  const L = window.__logosLector;
  let stopped = false, nuevos = 0;
  const nodes = el.querySelectorAll('[data-datatype="page"], p, h1, h2, h3, h4, h5, h6, li, blockquote');
  for (const n of nodes) {
    if (n.getAttribute('data-datatype') === 'page') {
      const ref = n.getAttribute('data-reference') || n.getAttribute('data-raw-reference');
      if (ref && ref !== L.page) { L.page = ref; const k = '⟦' + ref + '⟧'; if (!L.seen.has(k)) { L.seen.add(k); L.out.push(k); } }
      continue;
    }
    if (n.tagName !== 'LI' && n.parentElement && n.parentElement.closest('li')) continue;
    const t = n.textContent.replace(/\s+/g, ' ').trim();
    if (t.length < 2 || L.seen.has(t)) continue;
    L.seen.add(t); L.out.push(t); nuevos++;
    if (stopRegex && new RegExp(stopRegex).test(t)) { stopped = true; break; }
  }
  __save(L);
  const pages = L.out.filter((l) => l.startsWith('⟦')).map((l) => l.slice(1, -1));
  const pagesEnDom = [...nodes].filter((n) => n.getAttribute('data-datatype') === 'page').map((n) => n.getAttribute('data-reference'));
  return {
    nuevos, chars: L.out.join('\n').length, stopped,
    paginaActual: L.page, paginasEnPantalla: pagesEnDom,
    primero: L.out.find((l) => !l.startsWith('⟦'))?.slice(0, 90),
    ultimo: L.out.slice(-1)[0]?.slice(0, 90),
    encabezados: L.out.filter((l) => /^\d{1,3}:\d{1,3}/.test(l)).slice(-4),
  };
};

// Solo si el panel del navegador está VISIBLE: desplaza N pantallas acumulando.
// Devuelve stopped=true al encontrar stopRegex. Llamar varias veces (≤ 10 pasos por llamada).
window.logosScroll = async function ({ stopRegex = null, steps = 8, waitMs = 400 } = {}) {
  const el = document.querySelector('.resourceViewer_LHCJb');
  if (!el) return { error: 'no hay panel' };
  if (document.hidden) return { error: 'la pestaña está oculta: el desplazamiento no redibuja. Usa saltos por ?ref=page.N (ver lector-web.md)' };
  let r = window.logosChunk({ stopRegex }); let n = 0; const t0 = Date.now();
  while (!r.stopped && n < steps && el.scrollTop + el.clientHeight < el.scrollHeight - 2 && Date.now() - t0 < 20000) {
    const antes = el.scrollTop;
    el.scrollTop += el.clientHeight * 0.85; n++;
    await new Promise((res) => setTimeout(res, waitMs));
    r = window.logosChunk({ stopRegex });
    if (el.scrollTop === antes) { r.atascado = true; break; }
  }
  return { ...r, pasos: n, ms: Date.now() - t0 };
};

// El texto acumulado, con ⟦Page N⟧ intercalado. Es lo que se escribe en la nota de fuentes.
window.logosTexto = function () { return __load().out.join('\n'); };

// Número de la última página vista (para saltar a la siguiente con ?ref=page.N+1).
window.logosUltimaPagina = function () {
  const m = (__load().page || '').match(/(\d+)/); return m ? parseInt(m[1], 10) : null;
};
'lector-web.js cargado';
