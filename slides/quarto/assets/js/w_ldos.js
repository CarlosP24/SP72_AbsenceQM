// End-LDOS heat maps.
//
// 'ldos-vb': end LDOS of the partial shell vs (V_Z/V_Z^c, ω/Δ0) for χ = 1, 50, 100, 200 nm
//   (χ = 200 nm is the published case; the others are illustrative). data-chis="1,50,100,200"
//   lists the χ shown; step k shows the k-th one. The zero-bias peak that appears before
//   V_Z^c is marked as a quasi-MZM. data-marks="vz" marks V_Z^(1) and V_Z^(2). Each χ shown is
//   announced to the slide (event 'qm:chi'), for the cursor of an 'ldos-chi' next to it.
// 'ldos-chi': paper Fig. 2, end LDOS vs (χ, ω/Δ0) for the true MZM and the quasi-MZM.
//   data-rows="partial" or "partial,full". Steps (two rows): 0 partial row, 1 full row,
//   2 verdict tags and χ*, 3 hidden quasi-MZM energy (lowest pole of the closed wire).
//   data-set="dis": paper Fig. 3 (short-range disorder), rows only. data-cursor="1,50,..."
//   draws a χ cursor at the step-th value, or at the χ shown by an 'ldos-vb' on the slide.

QM.register('ldos-vb', (el, opts) => {
  const L = QMD.ldos_vB, C = QM.c;
  const chis = (opts.chis || '1,50,100,200').split(',').map((s) => s.trim());
  const marks = opts.marks === 'vz';
  const p = QM.panel(el, { x: 0, y: 0, w: +opts.w || 760, h: +opts.h || 500,
    m: { l: 84, r: 96, t: (chis.length > 1 ? 64 : 24) + (marks ? 38 : 0), b: 70 } });
  const X = d3.scaleLinear([0, 2], [0, p.iw]);
  const Y = d3.scaleLinear([-1, 1], [p.ih, 0]);
  // the maps span ω ∈ [ω0, ω1]; place each canvas over its own extent
  const w0 = L.ω[0], w1 = L.ω[L.ω.length - 1];
  const canv = {};
  chis.forEach((c) => {
    const cv = p.canvas();
    QM.heat(cv, L.maps[c]);
    cv.style.top = Y(w1) + 'px';
    cv.style.height = Y(w0) - Y(w1) + 'px';
    cv.style.left = X(L.VZ[0]) + 'px';
    cv.style.width = X(L.VZ[L.VZ.length - 1]) - X(L.VZ[0]) + 'px';
    cv.style.transition = 'opacity 0.6s ease';
    cv.style.opacity = 0;
    canv[c] = cv;
  });
  const clip = 'lv' + Math.random().toString(36).slice(2);
  p.svg.append('defs').append('clipPath').attr('id', clip).append('rect').attr('width', p.iw).attr('height', p.ih);
  p.g.append('line').attr('x1', X(1)).attr('x2', X(1)).attr('y2', p.ih).attr('stroke', C.crit)
    .attr('stroke-width', 2.2).attr('stroke-dasharray', '7 5');
  QM.axis(p, 'bottom', X, { ticks: [0, 1, 2] });
  QM.axis(p, 'left', Y, { ticks: [-1, 0, 1] });
  QM.frame(p);
  p.label(p.iw / 2, p.ih + 52, 'V_\\mathrm{Z}/V_\\mathrm{Z}^\\mathrm{c}', {});
  p.label(-60, p.ih / 2, '\\omega/\\Delta_0', {}).style.transform = 'translate(-50%,-50%) rotate(-90deg)';
  QM.colorbar(p, { x: p.iw + 18, ticks: ['0', '1'], label: 'LDOS (arb. u.)' });
  p.label(p.iw - 12, p.ih - 14, 'end LDOS', { ax: 1, ay: 1, math: false, cls: 'text' }).style.color = '#fff';

  // zero-bias peak extent along V_Z for each χ (from the ω = 0 row)
  const j0 = QM.nearest(L.ω, 0);
  const zbpStart = {};
  const i1 = L.VZ.findIndex((v) => v >= 1);
  chis.forEach((c) => {
    const q = L.maps[c], a = QM.u8(q);
    let i0 = i1;
    while (i0 > 0 && a[i0 - 1 + q.nx * j0] > 150) i0--;
    zbpStart[c] = L.VZ[i0];
  });
  // bars: MZM after V_Z^c, quasi-MZM before
  const bars = p.g.append('g').attr('clip-path', `url(#${clip})`);
  const bar = (x0, x1, yv) => {
    const g = bars.append('g');
    g.append('path').attr('d', `M${X(x0)},${Y(yv)} H${X(x1)} M${X(x0)},${Y(yv) - 7} v14 M${X(x1)},${Y(yv) - 7} v14`)
      .attr('stroke', '#fff').attr('stroke-width', 2.4).attr('fill', 'none');
    return g;
  };
  bar(1.0, 1.98, 0.32);
  // the two Zeeman fields of the phase-diagram slide, coloured by case (QM.caseColor) to
  // match the χ cursors of an 'ldos-chi' next to it
  if (marks) {
    const P = QMD.params;
    [[P.VZ1 / P.VZc, 1], [P.VZ2 / P.VZc, 2]].forEach(([v, n]) => {
      const col = QM.caseColor[n === 1 ? 'Majo' : 'QMajo'];
      p.g.append('path').attr('d', `M${X(v)},-2 l-9,-14 h18 z`).attr('fill', col);
      p.label(X(v), -20, `V_\\mathrm{Z}^{(${n})}`, { ay: 1, cls: 'small', color: col });
    });
  }
  const lMZM = p.label(X(marks ? 1.74 : 1.49), Y(0.32) - 8, 'MZM', { ay: 1, math: false, cls: 'text' });
  lMZM.style.color = '#fff'; lMZM.style.fontWeight = 700;
  const qBar = bars.append('g');
  const lQ = p.label(0, Y(-0.32) + 8, 'quasi-MZM', { ay: 0, math: false, cls: 'text' });
  lQ.style.color = '#fff'; lQ.style.fontWeight = 700;

  let btn = null;
  if (chis.length > 1) {
    btn = QM.buttons(el, { x: p.m.l, y: 8, items: chis.map((c) => ({ tex: `\\chi = ${c}\\ \\mathrm{nm}` })),
      onpick: (i) => show(i) });
    Object.assign(btn.el.style, { left: p.m.l + p.iw / 2 + 'px', transform: 'translateX(-50%)' });   // centred on the map
  }
  const slide = el.closest('section');
  function show(i) {
    const c = chis[i];
    chis.forEach((k) => { canv[k].style.opacity = k === c ? 1 : 0; });
    if (btn) btn.set(i);
    if (slide) slide.dispatchEvent(new CustomEvent('qm:chi', { detail: { chi: +c } }));
    qBar.selectAll('*').remove();
    const s = zbpStart[c];
    if (s !== null && s < 0.9) {
      const g = qBar.append('path')
        .attr('d', `M${X(s)},${Y(-0.32)} H${X(1)} M${X(s)},${Y(-0.32) - 7} v14 M${X(1)},${Y(-0.32) - 7} v14`)
        .attr('stroke', '#fff').attr('stroke-width', 2.4).attr('fill', 'none');
      lQ.style.left = p.m.l + (X(s) + X(1)) / 2 + 'px';
      lQ.style.opacity = 1;
    } else lQ.style.opacity = 0;
  }
  return { go(step) { show(Math.min(step, chis.length - 1)); } };
});

QM.register('ldos-chi', (el, opts) => {
  const dis = opts.set === 'dis';
  const L = dis ? QMD.ldos_dis : QMD.ldos_chi, P = QMD.params, C = QM.c;
  const rows = (opts.rows || 'partial,full').split(',').map((s) => s.trim());
  const cols = ['Majo', 'QMajo'];
  const W = +opts.w || 1400, rowH = 230, gut = 190, top = 46;
  const pw = (W - gut - 120) / 2;
  const X = d3.scaleLog([1, 3162], [0, pw - 20]);
  const Y = d3.scaleLinear([-0.2, 0.2], [rowH - 50, 0]);
  const grp = {};
  const panels = {};
  rows.forEach((r, ri) => {
    const rowEls = [];
    const y0 = top + ri * (rowH + 18);
    cols.forEach((c, ci) => {
      const p = QM.panel(el, { x: gut + ci * pw, y: y0, w: pw, h: rowH, m: { l: 0, r: 20, t: 0, b: 50 } });
      const cv = p.canvas();
      QM.heat(cv, L.maps[`${r}_${c}`]);
      QM.axis(p, 'bottom', X, { ticks: [1, 10, 100, 1000], fmt: d3.format('d'), labels: ri === rows.length - 1 });
      QM.axis(p, 'left', Y, { ticks: [-0.2, 0, 0.2], labels: ci === 0 });
      QM.frame(p);
      if (ri === rows.length - 1) p.label(p.iw / 2, p.ih + 46, '\\chi\\ (\\mathrm{nm})', {});
      const tag = r === 'partial' ? 'V_\\mathrm{Z} = V_\\mathrm{Z}^{(' : '\\Phi = \\Phi^{(';
      const lb = p.label(p.iw - 12, p.ih - 12, `${tag}${ci + 1})}`, { ax: 1, ay: 1, cls: 'small' });
      lb.style.color = '#fff';
      panels[`${r}_${c}`] = p;
      rowEls.push(p.box);
    });
    // row label with the device render
    const rl = QM.box(el, 0, y0 + 10, gut - 70, rowH - 60);
    rl.className = 'qm-box qm-rowlabel';
    const img = el.querySelector(`img.qm-asset[data-key="device_${r}"]`);
    if (img) rl.appendChild(img); else rl.innerHTML = `<img src="assets/img/device_${r}.png" alt="">`;
    rl.insertAdjacentHTML('beforeend', `<span>${r === 'partial' ? 'Partial shell' : 'Full shell'}</span>`);
    const yl = QM.box(el, gut - 62, y0 + (rowH - 50) / 2 - 12, 40, 24);
    QM.tex(yl, '\\omega/\\Delta_0');
    yl.style.transform = 'translate(-50%,0) rotate(-90deg)';
    yl.style.fontSize = '22px';
    rowEls.push(rl, yl);
    // colour bar of the row
    const cbp = QM.panel(el, { x: gut + 2 * pw - 6, y: y0, w: 110, h: rowH, m: { l: 0, r: 60, t: 0, b: 50 } });
    QM.colorbar(cbp, { x: 0, ticks: ['0', '1'], label: 'LDOS (arb. u.)' });
    rowEls.push(cbp.box);
    grp[r] = rowEls;
  });
  // column titles
  ['True MZM', 'Quasi-MZM'].forEach((t, ci) => {
    const b = QM.box(el, gut + ci * pw, 0, pw - 20, 36);
    b.className = 'qm-box qm-coltitle';
    b.textContent = t;
  });

  // verdict tags, χ* line and hidden energy (full row)
  const extras = [];
  const tagBox = (r, text, color) => {
    const p = panels[`${r}_QMajo`];
    const t = p.label(p.iw - 12, 12, text, { ax: 1, ay: 0, math: false, cls: 'tag' });
    t.style.background = color;
    t.classList.add('qm-fade');
    return t;
  };
  const tagP = dis ? null : tagBox('partial', 'False positive', C.red);
  extras.push(tagP);
  let tagF = null, star = [], hidden = [];
  if (rows.includes('full') && !dis) {
    tagF = tagBox('full', 'No false positive', C.green);
    const chiS = P.χvanish_QMZM;
    ['Majo', 'QMajo'].forEach((c) => {
      const p = panels[`full_${c}`];
      const g = p.g.append('g').attr('class', 'qm-fade');
      g.append('line').attr('x1', X(chiS)).attr('x2', X(chiS)).attr('y2', p.ih)
        .attr('stroke', '#fff').attr('stroke-width', 2.2).attr('stroke-dasharray', '6 5');
      star.push(g.node());
      if (c === 'Majo') {
        const a = p.label(X(chiS) - 10, 16, 'sharp end:<br>probe works', { ax: 1, ay: 0, math: false, cls: 'text' });
        const b = p.label(X(chiS) + 10, 16, 'smooth end:<br>trivial skin hides all', { ax: 0, ay: 0, math: false, cls: 'text' });
        [a, b].forEach((l) => { l.style.color = '#fff'; l.style.lineHeight = 1.2; l.style.whiteSpace = 'normal'; l.classList.add('qm-fade'); star.push(l); });
        b.style.width = '200px';
      }
    });
    // hidden quasi-MZM: ±E(χ) of the pair, from the m_J = 0 DOS once it leaves the gap edge
    // (or the closed-wire pole, where the state is localised, without data/DOS_vchi)
    const p = panels.full_QMajo;
    const D = L.Edos, E = L.E.full;
    const pts = D ? D.χ.map((x, i) => [x, D.E[i]]).filter(([, e], i) => D.pair[i] && e < 0.2)
      : E.χ.map((x, i) => [x, E.E[i]]).filter(([x, e]) => x >= 200 && e < 0.2);
    const g = p.g.append('g').attr('class', 'qm-fade');
    const lf = d3.line().x((d) => X(d[0])).y((d) => Y(d[1]));
    // with the DOS the pair starts at ≈ 10⁻² Δ0: ±E are a few px apart on this axis, so one line
    const sides = D ? [1] : [1, -1];
    sides.forEach((s) => g.append('path').attr('d', lf(pts.map(([x, e]) => [x, D ? 0 : s * e]))).attr('fill', 'none')
      .attr('stroke', '#fff').attr('stroke-width', 2.4).attr('stroke-dasharray', '6 4'));
    const hl = p.label(X(95), Y(-0.1), 'hidden quasi-MZM →<br>pinned, deep inside', { ax: 0.5, math: false, cls: 'text' });
    hl.style.color = '#fff'; hl.style.textAlign = 'center'; hl.style.lineHeight = 1.2;
    hl.classList.add('qm-fade');
    hidden = [g.node(), hl];
  }
  // χ cursor: a marker on top of each map, coloured by case (QM.caseColor)
  let cursorAt = () => {};
  if (opts.cursor) {
    const list = opts.cursor.split(',').map(Number);
    const gs = Object.entries(panels).map(([k, p]) => {
      const g = p.g.append('g').style('transition', 'transform 0.6s ease');
      g.append('path').attr('d', 'M0,-3 l-9,-14 h18 z').attr('fill', QM.caseColor[k.split('_')[1]]);
      return g;
    });
    const place = (chi) => gs.forEach((g) => g.style('transform', `translateX(${Math.max(X(chi), 1.5)}px)`));
    const slide = el.closest('section');
    if (slide) slide.addEventListener('qm:chi', (e) => place(e.detail.chi));
    cursorAt = (step) => place(list[Math.min(step, list.length - 1)]);
  }
  const vis = (nodes, on) => nodes.forEach((n) => { if (n) (n.style || n).opacity = on ? 1 : 0; });
  Object.values(grp).flat().forEach((n) => n.classList.add('qm-fade'));
  return {
    go(step) {
      cursorAt(step);
      const two = rows.length > 1;
      if (!two) { vis([tagP], step >= (+opts.tagstep || 1)); return; }
      vis(grp.full, step >= 1);
      vis([tagP], true);
      vis([tagF], step >= 2);
      vis(star, step >= 2);
      vis(hidden, step >= 3);
    },
  };
});
