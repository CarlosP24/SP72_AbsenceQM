// Full-shell widgets.
//
// 'lp': Little–Parks lobes. The shell pairing Δ e^{inφ} winds n = ⌊Φ/Φ0⌉ times around the
//   wire (ring coloured by its phase, romaO) and the shell gap Ω(Φ) shrinks away from
//   integer flux (illustrative calculation for the paper's shell, slides/data/lp_lobes.jld2).
//   Steps: 0 Φ = 0, 1 sweep to Φ = 2.4 Φ0, 2 the odd lobe highlighted.
// 'sectors': DOS vs (Φ, ω) of the full shell (paper Fig. 1g data) split into the m_J = 0
//   sector (class BDI, red) and all the others (CdGM analogs, grey-blue).
//   Steps: 0 all sectors (paper colour map), 1 the m_J ≠ 0 sectors, 2 the m_J = 0 sector on top.
// 'dos-zoom': m_J = 0 DOS of lobe 1 near zero energy (paper Fig. 1h): MZM below Φ^c,
//   quasi-MZM above.

QM.register('lp', (el) => {
  const D = QMD.lp, C = QM.c, lut = QMD.cmap.romaO;
  const P1 = QMD.params['Φ1'];                    // where the flux rests in the odd lobe
  // ring
  const R = 120, r0 = 78, size = 2 * R + 20;
  const box = QM.box(el, 0, 40, size, size);
  const cv = document.createElement('canvas');
  cv.width = 2 * size; cv.height = 2 * size;
  Object.assign(cv.style, { width: size + 'px', height: size + 'px', position: 'absolute' });
  box.appendChild(cv);
  const nLab = QM.box(el, 0, 40 + size / 2 - 18, size, 36);
  nLab.className = 'qm-box qm-nlabel';
  const ringCap = QM.box(el, 0, 40 + size + 8, size, 30);
  ringCap.className = 'qm-box qm-ringcap';
  QM.tex(ringCap, '\\arg\\Delta = n\\varphi');
  const drawRing = (n) => {
    const ctx = cv.getContext('2d');
    const img = ctx.createImageData(cv.width, cv.height);
    const c0 = cv.width / 2, s = 2;
    for (let j = 0; j < cv.height; j++) {
      for (let i = 0; i < cv.width; i++) {
        const dx = (i - c0) / s, dy = (c0 - j) / s, rr = Math.hypot(dx, dy);
        const k = 4 * (i + cv.width * j);
        if (rr < r0 || rr > R) continue;
        const ph = (n * Math.atan2(dy, dx)) / (2 * Math.PI);
        const t = ((ph % 1) + 1) % 1;
        const c = lut[Math.min(255, Math.floor(256 * t))];
        const edge = Math.min(1, R - rr, rr - r0);
        img.data[k] = c[0]; img.data[k + 1] = c[1]; img.data[k + 2] = c[2]; img.data[k + 3] = 255 * Math.min(1, edge * s);
      }
    }
    ctx.putImageData(img, 0, 0);
    QM.tex(nLab, `n = ${n}`);
  };

  // Ω(Φ)
  const p = QM.panel(el, { x: size + 40, y: 0, w: 640, h: 380, m: { l: 74, r: 14, t: 44, b: 64 } });
  const X = d3.scaleLinear([0, 2.5], [0, p.iw]);
  const Y = d3.scaleLinear([0, 1.08], [p.ih, 0]);
  const odd = p.g.append('rect').attr('x', X(0.5)).attr('width', X(1.5) - X(0.5)).attr('height', p.ih)
    .attr('fill', C.red_tint).attr('class', 'qm-fade').style('opacity', 0);
  const pts = D['Φ'].map((f, i) => [f, D['Ω'][i]]).filter(([f]) => f >= 0 && f <= 2.5);
  p.g.append('path').attr('d', d3.area().x((d) => X(d[0])).y0(p.ih).y1((d) => Y(d[1]))(pts))
    .attr('fill', '#B8C7F9').attr('fill-opacity', 0.85);
  p.g.append('path').attr('d', d3.line().x((d) => X(d[0])).y((d) => Y(d[1]))(pts))
    .attr('fill', 'none').attr('stroke', C.ink).attr('stroke-width', 2.8);
  [0.5, 1.5].forEach((f) => p.g.append('line').attr('x1', X(f)).attr('x2', X(f)).attr('y2', p.ih)
    .attr('stroke', C.muted).attr('stroke-dasharray', '5 5').attr('stroke-width', 1.5));
  QM.axis(p, 'bottom', X, { ticks: [0, 0.5, 1, 1.5, 2, 2.5] });
  QM.axis(p, 'left', Y, { ticks: [0, 0.5, 1] });
  QM.frame(p);
  p.label(p.iw / 2, p.ih + 50, '\\Phi/\\Phi_0', {});
  p.label(-56, p.ih / 2, '\\Omega/\\Delta_0', {}).style.transform = 'translate(-50%,-50%) rotate(-90deg)';
  [[0.25, 'n = 0'], [1, 'n = 1'], [2, 'n = 2']].forEach(([f, t]) => p.label(X(f), -18, t, { math: false, cls: 'text' }));
  p.label(p.iw - 10, p.ih - 12, 'shell gap', { ax: 1, ay: 1, math: false, cls: 'text' }).style.color = C.ink_2;
  const oddLab = p.label(X(1.2), Y(0.2), 'odd lobe:<br>Majoranas<br>possible', { math: false, cls: 'text' });
  Object.assign(oddLab.style, { color: C.red, fontWeight: 700, textAlign: 'center', lineHeight: 1.15, opacity: 0 });
  oddLab.classList.add('qm-fade');
  const cur = p.g.append('line').attr('y2', p.ih).attr('stroke', C.red).attr('stroke-width', 2.2);
  const dot = p.g.append('circle').attr('r', 7).attr('fill', C.red).attr('stroke', '#fff').attr('stroke-width', 2);

  const sl = QM.slider(el, { x: size + 40 + 74, y: 392, w: 520, min: 0, max: 2.5, step: 0.005, value: 0,
    tex: '\\Phi/\\Phi_0', fmt: (v) => v.toFixed(2), oninput: (v) => { stop(); draw(v); } });
  let nNow = null;
  function draw(f) {
    const n = Math.round(f);
    if (n !== nNow) { drawRing(n); nNow = n; }
    cur.attr('x1', X(f)).attr('x2', X(f));
    dot.attr('cx', X(f)).attr('cy', Y(QM.interp(D['Φ'], D['Ω'], f)));
    sl.set(f);
  }
  let stop = () => {};
  return {
    go(step, animate) {
      stop();
      odd.style('opacity', step >= 2 ? 1 : 0);
      oddLab.style.opacity = step >= 2 ? 1 : 0;
      if (step === 0) { draw(0); return; }
      if (!animate) { draw(step >= 2 ? P1 : 2.4); return; }
      if (step === 1) { const from = sl.value; stop = QM.tween(5000, (t) => draw(QM.lerp(from, 2.4, t))); }
      if (step === 2) { const from = sl.value; stop = QM.tween(1200, (t) => draw(QM.lerp(from, P1, t))); }
    },
    leave() { stop(); },
  };
});

QM.register('sectors', (el, opts) => {
  const S = QMD.dos_sectors, C = QM.c;
  const p = QM.panel(el, { x: 0, y: 46, w: +opts.w || 900, h: +opts.h || 470, m: { l: 84, r: 30, t: 40, b: 64 } });
  const X = d3.scaleLinear([0, 2.5], [0, p.iw]);
  const Y = d3.scaleLinear([-1.1, 1.1], [p.ih, 0]);
  const cTot = p.canvas(), cMix = p.canvas();
  [cTot, cMix].forEach((c) => {
    c.style.left = X(S['Φ'][0]) + 'px';
    c.style.width = X(S['Φ'][S['Φ'].length - 1]) - X(S['Φ'][0]) + 'px';
    c.style.top = Y(S.ω[S.ω.length - 1]) + 'px';
    c.style.height = Y(S.ω[0]) - Y(S.ω[S.ω.length - 1]) + 'px';
    c.style.transition = 'opacity 0.6s ease';
  });
  QM.heat(cTot, S.total);
  // two-channel composite: m_J ≠ 0 in grey-blue, m_J = 0 in red, on a dark ground
  const mix = (wOthers, wMj0) => {
    const o = QM.u8(S.others), z = QM.u8(S.mj0);
    const nx = S.others.nx, ny = S.others.ny;
    cMix.width = nx; cMix.height = ny;
    const ctx = cMix.getContext('2d');
    const img = ctx.createImageData(nx, ny);
    const bg = [12, 18, 38], cA = [190, 205, 235], cB = [255, 64, 84];
    for (let j = 0; j < ny; j++) {
      for (let i = 0; i < nx; i++) {
        const a = Math.sqrt(o[i + nx * j] / 255) * wOthers, b = Math.pow(z[i + nx * j] / 255, 0.8) * wMj0;
        const k = 4 * (i + nx * (ny - 1 - j));
        for (let c = 0; c < 3; c++) img.data[k + c] = Math.min(255, bg[c] + a * (cA[c] - bg[c]) + b * cB[c]);
        img.data[k + 3] = 255;
      }
    }
    ctx.putImageData(img, 0, 0);
  };
  [0.5, 1.5].forEach((f) => p.g.append('line').attr('x1', X(f)).attr('x2', X(f)).attr('y2', p.ih)
    .attr('stroke', 'rgba(255,255,255,0.55)').attr('stroke-dasharray', '3 4').attr('stroke-width', 1.5));
  QM.axis(p, 'bottom', X, { ticks: [0, 0.5, 1, 1.5, 2, 2.5] });
  QM.axis(p, 'left', Y, { ticks: [-1, 0, 1] });
  QM.frame(p);
  p.label(p.iw / 2, p.ih + 50, '\\Phi/\\Phi_0', {});
  p.label(-58, p.ih / 2, '\\omega/\\Delta_0', {}).style.transform = 'translate(-50%,-50%) rotate(-90deg)';
  [[0.25, 'n = 0'], [1, 'n = 1'], [2, 'n = 2']].forEach(([f, t]) => p.label(X(f), -18, t, { math: false, cls: 'text' }));
  const noMj = [0.25, 2.0].map((f) => {
    const l = p.label(X(f), Y(0), 'no <i>m</i><sub>J</sub> = 0<br>sector', { math: false, cls: 'text' });
    Object.assign(l.style, { color: '#fff', textAlign: 'center', lineHeight: 1.2 });
    l.classList.add('qm-fade');
    return l;
  });
  const legend = QM.box(el, p.m.l, 0, 900, 36);
  legend.className = 'qm-box qm-legend';
  legend.innerHTML = '<span class="sw" style="background:#BECDEB"></span><span><i>m</i><sub>J</sub> ≠ 0 · CdGM analogs · class AI</span>' +
    '<span class="sw" style="background:#FF4054"></span><span><i>m</i><sub>J</sub> = 0 · class BDI</span>';
  legend.classList.add('qm-fade');
  return {
    go(step) {
      cTot.style.opacity = step === 0 ? 1 : 0;
      cMix.style.opacity = step === 0 ? 0 : 1;
      legend.style.opacity = step === 0 ? 0 : 1;
      noMj.forEach((l) => { l.style.opacity = step >= 2 ? 1 : 0; });
      if (step === 1) mix(0.85, 0);
      if (step >= 2) mix(0.5, 1);
    },
  };
});

QM.register('dos-zoom', (el, opts) => {
  const Z = QMD.dos_mj0_zoom, P = QMD.params, C = QM.c;
  const p = QM.panel(el, { x: 0, y: 0, w: +opts.w || 620, h: +opts.h || 470, m: { l: 84, r: 100, t: 46, b: 64 } });
  const X = d3.scaleLinear([0.5, 1.5], [0, p.iw]);
  const Y = d3.scaleLinear([-0.113, 0.113], [p.ih, 0]);
  const cv = p.canvas();
  QM.heat(cv, Z.map);
  cv.style.left = X(Z['Φ'][0]) + 'px';
  cv.style.width = X(Z['Φ'][Z['Φ'].length - 1]) - X(Z['Φ'][0]) + 'px';
  cv.style.top = Y(Z.ω[Z.ω.length - 1]) + 'px';
  cv.style.height = Y(Z.ω[0]) - Y(Z.ω[Z.ω.length - 1]) + 'px';
  const Pc = P['Φc'];
  p.g.append('line').attr('x1', X(Pc)).attr('x2', X(Pc)).attr('y2', p.ih).attr('stroke', C.crit)
    .attr('stroke-width', 2.2).attr('stroke-dasharray', '7 5');
  QM.axis(p, 'bottom', X, { ticks: [0.5, 1, 1.5] });
  QM.axis(p, 'left', Y, { ticks: [-0.1, 0, 0.1] });
  QM.frame(p);
  p.label(X(Pc), p.ih + 14, '\\Phi^\\mathrm{c}', { ay: 0, cls: 'small' }).style.color = C.crit;
  p.label(p.iw / 2, p.ih + 50, '\\Phi/\\Phi_0', {});
  p.label(-60, p.ih / 2, '\\omega/\\Delta_0', {}).style.transform = 'translate(-50%,-50%) rotate(-90deg)';
  [[P['Φ1'], '\\Phi^{(1)}'], [P['Φ2'], '\\Phi^{(2)}']].forEach(([f, t]) => {
    p.g.append('line').attr('x1', X(f)).attr('x2', X(f)).attr('y1', -8).attr('y2', 0).attr('stroke', C.ink).attr('stroke-width', 1.5);
    p.label(X(f), -12, t, { ay: 1, cls: 'small' });
  });
  const bar = (x0, x1, yv, text, below) => {
    p.g.append('path').attr('d', `M${X(x0)},${Y(yv)} H${X(x1)} M${X(x0)},${Y(yv) - 6} v12 M${X(x1)},${Y(yv) - 6} v12`)
      .attr('stroke', '#fff').attr('stroke-width', 2.2).attr('fill', 'none');
    const l = p.label((X(x0) + X(x1)) / 2, Y(yv) + (below ? 10 : -10), text, { ay: below ? 0 : 1, math: false, cls: 'text' });
    l.style.color = '#fff'; l.style.fontWeight = 700;
  };
  bar(0.505, Pc, 0.018, 'MZM', false);
  bar(Pc, 0.98, -0.018, 'quasi-MZM', true);
  QM.colorbar(p, { x: p.iw + 18, ticks: ['0.1', '1'], label: 'DOS (arb. u.)' });
  return {};
});

// 'potential': gate potential inside the grounded shell (Eq. A1), longitudinal cut in units of
// R and χ, and the local chemical potential it leaves for the m_J = 0, m_r = 1 mode.
QM.register('potential', (el) => {
  const G = QMD.phig, M = QMD.muz, C = QM.c;
  const p = QM.panel(el, { x: 0, y: 0, w: 760, h: 380, m: { l: 70, r: 20, t: 30, b: 64 } });
  const X = d3.scaleLinear([-0.8, 6], [0, p.iw]);
  const Y = d3.scaleLinear([-1.32, 1.32], [p.ih, 0]);
  const blues = d3.range(256).map((i) => { const c = d3.rgb(d3.interpolateBlues(0.03 + 0.9 * (i / 255))); return [c.r, c.g, c.b]; });
  const cv = p.canvas();
  QM.heat(cv, G.map, { lut: blues });
  Object.assign(cv.style, { left: X(0) + 'px', width: X(6) - X(0) + 'px', top: Y(1) + 'px', height: Y(-1) - Y(1) + 'px' });
  // shell and barrier
  [[1, 1.3], [-1.3, -1]].forEach(([a, b]) => p.g.append('rect').attr('x', X(0)).attr('width', X(6) - X(0))
    .attr('y', Y(b)).attr('height', Y(a) - Y(b)).attr('fill', '#B8C7F9'));
  p.g.append('rect').attr('x', X(-0.8)).attr('width', X(0) - X(-0.8)).attr('y', Y(1)).attr('height', Y(-1) - Y(1)).attr('fill', '#BDBDBD');
  p.label(X(-0.4), Y(0), 'gate', { math: false, cls: 'text' }).style.transform = 'translate(-50%,-50%) rotate(-90deg)';
  p.label(X(3), Y(1.15), '\\text{grounded shell: } \\phi_g(R, z) = 0', { cls: 'small' });
  p.label(X(0.12), Y(-0.75), 'e\\phi_g = \\mu_\\mathrm{bulk}', { ax: 0, cls: 'small' }).style.color = '#fff';
  const zt = [0, 2, 4, 6];
  QM.axis(p, 'bottom', X, { ticks: zt, fmt: (v) => (v === 0 ? '0' : '') });
  zt.slice(1).forEach((v) => p.label(X(v), p.ih + 22, `${v}\\chi`, { ay: 0, cls: 'small' }));
  p.label(X(5), p.ih + 22, 'z', { ay: 0 });
  QM.axis(p, 'left', Y, { ticks: [-1, 0, 1], fmt: (v) => (v === 0 ? '0' : v > 0 ? 'R' : '−R') });
  p.label(-50, Y(0), 'r', {});
  // μ(z) for the m_J = 0, m_r = 1 mode vs the slowest Bessel mode alone
  const q = QM.panel(el, { x: 800, y: 0, w: 560, h: 380, m: { l: 70, r: 20, t: 30, b: 64 } });
  const x2 = d3.scaleLinear([0, 6], [0, q.iw]), y2 = d3.scaleLinear([0, 1.05], [q.ih, 0]);
  const pts = M.zpos.map((z, i) => [z, M.full2[i]]).filter(([z]) => z <= 6);
  q.g.append('path').attr('d', d3.line().x((d) => x2(d[0])).y((d) => y2(1 - Math.exp(-d[0])))(pts))
    .attr('fill', 'none').attr('stroke', C.muted).attr('stroke-width', 2.4).attr('stroke-dasharray', '7 5');
  q.g.append('path').attr('d', d3.line().x((d) => x2(d[0])).y((d) => y2(d[1]))(pts))
    .attr('fill', 'none').attr('stroke', C.ink).attr('stroke-width', 3.2);
  q.g.append('line').attr('x2', q.iw).attr('y1', y2(1)).attr('y2', y2(1)).attr('stroke', C.line).attr('stroke-width', 1.5);
  QM.axis(q, 'bottom', x2, { ticks: zt, fmt: (v) => (v === 0 ? '0' : '') });
  zt.slice(1).forEach((v) => q.label(x2(v), q.ih + 22, `${v}\\chi`, { ay: 0, cls: 'small' }));
  QM.axis(q, 'left', y2, { ticks: [0, 0.5, 1] });
  QM.frame(q);
  q.label(-52, q.ih / 2, '\\mu(z)/\\mu_\\mathrm{bulk}', {}).style.transform = 'translate(-50%,-50%) rotate(-90deg)';
  const lg = (yv, dash, color, tex) => {
    q.g.append('line').attr('x1', x2(2.6)).attr('x2', x2(3.2)).attr('y1', y2(yv)).attr('y2', y2(yv))
      .attr('stroke', color).attr('stroke-width', dash ? 2.4 : 3.2).attr('stroke-dasharray', dash ? '7 5' : null);
    q.label(x2(3.35), y2(yv), tex, { ax: 0, cls: 'small', color });
  };
  lg(0.32, false, C.ink, '\\text{mode } m_J = 0,\\ m_r = 1');
  lg(0.18, true, C.muted, '1 - e^{-z/\\chi}');
  return {};
});
