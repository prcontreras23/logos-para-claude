// Extractor de resultados de búsqueda de Logos Web (app.logos.com/search) para el
// navegador integrado de Claude. Pegar ENTERO en javascript_tool cuando la página de
// búsqueda ya cargó; devuelve los resultados visibles como lista. Ver lector-web.md.
//
// Cada resultado: obra, ID del recurso, sección, extracto, cita (con página si la hay),
// cuántas veces aparece el término en esa sección y el enlace que abre el libro en ese
// punto exacto. Las clases de Logos Web llevan un sufijo generado (result_n8syd), por eso
// se buscan por prefijo. Los encabezados de obra y las tarjetas son hermanos en una lista
// plana: la obra de cada tarjeta es el último encabezado anterior en orden del documento.
(function (max = 60) {
  const abs = (h) => (h && h.startsWith('/') ? 'https://app.logos.com' + h : h);
  const limpio = (s) => (s || '').replace(/\s+/g, ' ').trim();
  const esCard = (n) => n.matches('[class*="summarizablePreviewWrapper"]');
  const nodos = [...document.querySelectorAll('[class*="summarizablePreviewWrapper"], a[href^="/books/LLS"]')]
    .filter((n) => esCard(n) || (!/\/(articles|offsets)\//.test(n.getAttribute('href')) && !n.closest('[class*="summarizablePreviewWrapper"]') && n.closest('[class*="searchPanelBody"]')));
  let obra = null; const res = [];
  for (const n of nodos) {
    if (!esCard(n)) { obra = limpio(n.textContent); continue; }
    const off = n.querySelector('a[href*="/offsets/"]');
    const art = n.querySelector('a[href*="/articles/"]');
    const href = off?.getAttribute('href') || art?.getAttribute('href');
    if (!href) continue;
    const seccion = art ? limpio(art.textContent) : null;
    let texto = limpio(n.textContent).replace(/Summarize$/, '').trim();
    if (seccion && texto.startsWith(seccion)) texto = texto.slice(seccion.length).trim();
    let veces = null; const mv = texto.match(/\((\d+) times?\)$/);
    if (mv) { veces = parseInt(mv[1], 10); texto = texto.slice(0, mv.index).trim(); }
    const corte = texto.lastIndexOf('…');
    res.push({
      obra,
      recurso: decodeURIComponent(href.match(/\/books\/([^/?]+)/)[1]),
      seccion,
      extracto: (corte > 0 ? texto.slice(0, corte + 1) : texto).slice(0, 500),
      cita: corte > 0 ? texto.slice(corte + 1).trim() : null,
      veces,
      abrir: abs(href),
    });
    if (res.length >= max) break;
  }
  // En la vista por relevancia no hay encabezados de obra: la cita empieza por el título.
  return { url: location.href, mostrados: res.length, resultados: res };
})();
