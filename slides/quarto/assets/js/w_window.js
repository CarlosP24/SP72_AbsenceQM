// One length scale, two effects. Top: energy of the quasi-MZM pair vs χ in both geometries
// (split end-LDOS peak for small χ in the partial shell; lowest pole of the closed wire where
// the pair is a localised state, data/E_QMZM). Bottom: the χ windows where the pair is
// visible at the probe (end LDOS above 1 % of its maximum, paper Fig. 2 data) and where it
// is pinned to zero (E < 10⁻² Δ0). They overlap in partial shells (false positives) and are
// a decade apart in full shells, where the trivial skin (≈ 3.5χ) grows with the same χ.
// Steps: 0 partial shell, 1 full shell, 2 the gap.
QM.register('window', (el) => {
  const L = QMD.ldos_chi, P = QMD.params, C = QM.c;
  const Ethr = 1e-2;
  const X0 = 1, X1 = 3162;

  // energies
  const mp = L.maps.partial_QMajo, a = QM.u8(mp);
  const iw0 = L.ω.findIndex((w) => w > 1e-9);
  const splitP = L.χ.map((chi, i) => {
    let best = iw0, bv = -1;
    for (let j = iw0; j < mp.ny; j++) { const v = a[i + mp.nx * j]; if (v > bv) { bv = v; best = j; } }
    return [chi, L.ω[best]];
  }).filter(([chi, e]) => chi < 75 && e > 0.003);
  // pole energies until they leave the plot (beyond, the closed wire is numerically at zero)
  const untilFloor = (arr) => { const k = arr.findIndex(([, e]) => !(e > 1e-7)); return k < 0 ? arr : arr.slice(0, k + 1); };
  const EP = splitP.concat(untilFloor(L.E.partial.χ.map((x, i) => [x, L.E.partial.E[i]]).filter(([x]) => x >= 75)));
  const EF = untilFloor(L.E.full.χ.map((x, i) => [x, L.E.full.E[i]]).filter(([x]) => x >= 200));
  const firstBelow = (arr) => { const d = arr.find(([, e]) => e < Ethr); return d ? d[0] : null; };
  const pinP = firstBelow(EP), pinF = EF.length ? EF[0][0] : null;
  const visF = P.χvanish_QMZM;

  // ---------------------------------------------------------------- energies (top)
  const T = QM.panel(el, { x: 0, y: 0, w: 1400, h: 280, m: { l: 250, r: 40, t: 14, b: 26 } });
  const X = d3.scaleLog([X0, X1], [0, T.iw]);
  const Y = d3.scaleLog([1e-6, 1], [T.ih, 0]);
  T.g.append('line').attr('x2', T.iw).attr('y1', Y(Ethr)).attr('y2', Y(Ethr))
    .attr('stroke', C.muted).attr('stroke-dasharray', '6 5').attr('stroke-width', 1.6);
  T.label(T.iw - 8, Y(Ethr) - 8, 'pinned:&nbsp; E &lt; 10<sup>−2</sup>Δ<sub>0</sub>', { ax: 1, ay: 1, math: false, cls: 'text' }).style.color = C.muted;
  const clip = 'wc' + Math.random().toString(36).slice(2);
  T.svg.append('defs').append('clipPath').attr('id', clip).append('rect').attr('width', T.iw).attr('height', T.ih);
  const lf = d3.line().x((d) => X(d[0])).y((d) => Y(Math.max(d[1], 1e-7)));
  const cP = T.g.append('path').attr('clip-path', `url(#${clip})`).attr('d', lf(EP)).attr('fill', 'none')
    .attr('stroke', C.navy).attr('stroke-width', 3.2).attr('class', 'qm-fade');
  const cF = T.g.append('path').attr('clip-path', `url(#${clip})`).attr('d', lf(EF)).attr('fill', 'none')
    .attr('stroke', C.green).attr('stroke-width', 3.2).attr('class', 'qm-fade');
  QM.axis(T, 'left', Y, { ticks: [1e-6, 1e-4, 1e-2, 1], fmt: () => '' });
  [[-6, 1e-6], [-4, 1e-4], [-2, 1e-2]].forEach(([e, v]) => T.label(-12, Y(v), `10^{${e}}`, { ax: 1, cls: 'small' }));
  T.label(-12, Y(1), '1', { ax: 1, math: false, cls: 'text' });
  QM.axis(T, 'bottom', X, { ticks: [1, 10, 100, 1000], fmt: () => '' });
  QM.frame(T);
  T.label(-74, T.ih / 2, 'E/\\Delta_0', {}).style.transform = 'translate(-50%,-50%) rotate(-90deg)';
  const tl = T.label(-104, T.ih / 2, 'quasi-MZM<br>energy', { ax: 1, math: false, cls: 'text' });
  Object.assign(tl.style, { textAlign: 'right', lineHeight: 1.2, fontWeight: 600, fontSize: '20px' });
  const lP = T.label(X(30), Y(0.3), 'partial shell', { math: false, cls: 'text', ay: 1 });
  lP.style.color = C.navy; lP.classList.add('qm-fade');
  const lF = T.label(X(700), Y(1.5e-3), 'full shell<br>(hidden, inside)', { math: false, cls: 'text', ax: 0 });
  Object.assign(lF.style, { color: C.green, lineHeight: 1.2 }); lF.classList.add('qm-fade');

  // ---------------------------------------------------------------- windows (bottom)
  const B = QM.panel(el, { x: 0, y: 290, w: 1400, h: 250, m: { l: 250, r: 40, t: 10, b: 60 } });
  const XB = d3.scaleLog([X0, X1], [0, B.iw]);
  QM.axis(B, 'bottom', XB, { ticks: [1, 10, 100, 1000], fmt: d3.format('d') });
  B.g.append('line').attr('x2', B.iw).attr('y1', B.ih).attr('y2', B.ih).attr('stroke', C.ink).attr('stroke-width', 1.3);
  B.label(B.iw / 2, B.ih + 46, '\\chi\\ (\\mathrm{nm})', {});
  const rowY = [30, 120];
  const rowG = [B.g.append('g').attr('class', 'qm-fade'), B.g.append('g').attr('class', 'qm-fade')];
  const rowLab = [];
  const bar = (g, x0, x1, y, color, text) => {
    g.append('rect').attr('x', XB(x0)).attr('y', y).attr('width', XB(x1) - XB(x0)).attr('height', 26)
      .attr('rx', 13).attr('fill', color);
    const t = B.label(XB(x0) + 14, y + 13, text, { ax: 0, math: false, cls: 'text' });
    t.style.color = '#fff'; t.style.fontWeight = 600; t.classList.add('qm-fade');
    return t;
  };
  // partial shell
  const yA = rowY[0], yB = rowY[0] + 34;
  const pa = [bar(rowG[0], X0, X1, yA, C.navy, 'visible at the probe')];
  if (pinP) pa.push(bar(rowG[0], pinP, X1, yB, C.orange, 'pinned to zero'));
  rowG[0].append('rect').attr('x', XB(pinP) - 6).attr('y', yA - 8).attr('width', XB(X1) - XB(pinP) + 6)
    .attr('height', 34 + 26 + 16).attr('rx', 10).attr('fill', 'none').attr('stroke', C.red).attr('stroke-width', 3);
  const fp = B.label(XB(X1), yA - 14, 'false positives', { ax: 1, ay: 1, math: false, cls: 'text' });
  Object.assign(fp.style, { color: C.red, fontWeight: 700 });
  pa.push(fp);
  // full shell
  const fa = [];
  const yC = rowY[1], yD = rowY[1] + 34;
  fa.push(bar(rowG[1], X0, visF, yC, C.navy, 'visible'));
  if (pinF) fa.push(bar(rowG[1], pinF, X1, yD, C.orange, 'pinned (hidden)'));
  // gap annotation
  const gapG = B.g.append('g').attr('class', 'qm-fade');
  const ym = (yC + yD + 26) / 2;
  gapG.append('path').attr('d', `M${XB(visF) + 6},${ym} H${XB(pinF) - 6}`).attr('stroke', C.green).attr('stroke-width', 3);
  gapG.append('path').attr('d', `M${XB(visF) + 4},${ym} l12,-7 v14 z M${XB(pinF) - 4},${ym} l-12,-7 v14 z`).attr('fill', C.green);
  const gl = B.label((XB(visF) + XB(pinF)) / 2, ym - 10, 'no window', { ay: 1, math: false, cls: 'text' });
  Object.assign(gl.style, { color: C.green, fontWeight: 700 });
  gl.classList.add('qm-fade');
  // row labels
  ['Partial shell', 'Full shell'].forEach((t, i) => {
    const l = B.label(-24, rowY[i] + 30, t, { ax: 1, math: false, cls: 'text' });
    Object.assign(l.style, { fontSize: '22px', fontWeight: 600 });
    l.classList.add('qm-fade');
    rowLab.push(l);
  });

  const vis = (nodes, on) => nodes.forEach((n) => { if (n) (n.style || n).opacity = on ? 1 : 0; });
  return {
    go(step) {
      vis([cP.node(), lP, rowG[0].node(), rowLab[0], ...pa], true);
      vis([cF.node(), lF, rowG[1].node(), rowLab[1], ...fa], step >= 1);
      vis([gapG.node(), gl], step >= 2);
    },
  };
});
