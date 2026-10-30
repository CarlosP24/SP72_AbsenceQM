// Full-shell widgets.
//
// 'lp': Little–Parks lobes. The shell pairing Δ e^{inφ} winds n = ⌊Φ/Φ0⌉ times around the
//   wire and the shell gap Ω(Φ) shrinks away from integer flux (illustrative calculation for
//   the paper's shell, slides/data/lp_lobes.jld2). The ring shows the phase nφ as arrows (going
//   once around, they turn n times) and the circulating supercurrent I_s ∝ |Δ|² (n − Φ/Φ0) as
//   two curved arrows spinning around the shell while the slide is on: anticlockwise for
//   I_s > 0, clockwise for I_s < 0, at a speed ∝ |I_s|; at integer flux they stand still.
//   Above Ω(Φ), the kinetic energy of that current, E_I ∝ (n − Φ/Φ0)², one parabola per n; the
//   shell sits on the lowest (n jumps at half-integer flux) and the gap dips where E_I peaks.
//   Steps: 0 Φ = 0, 1 sweep lobe 0, 2 on to Φ = 2.4 Φ0, 3 the odd lobe highlighted.
// 'sectors': DOS vs (Φ, ω) of the full shell (paper Fig. 1g data) split into the m_J = 0
//   sector (class D, red) and all the others (CdGM analogs, class A, grey-blue).
//   Steps: 0 all sectors (paper colour map), 1 the m_J ≠ 0 sectors, 2 the m_J = 0 sector on top.
// 'fs-maps': the full-shell version of the false-positive slide, vs (Φ, ω) in lobe 1 on the
//   grid of paper Fig. 1h: end LDOS (left, what the probe sees) and m_J = 0 DOS where μ(z)
//   varies (right, what is inside), for χ = 5, 20, 200, 500, 1000 nm (illustrative, keys
//   base_fs_zoom_chi=<χ>_ldosvPhi and _dos of src/main.jl; the 1000 nm DOS is Fig. 1h itself).
//   Step k shows the k-th χ in both; the buttons stay live. data-bars lists the χ at which the
//   MZM and quasi-MZM are marked on the DOS (default 1000).

QM.register('lp', (el) => {
  const D = QMD.lp, C = QM.c;
  const P1 = QMD.params['Φ1'];                    // where the flux rests in the odd lobe
  // circulating supercurrent of the shell, I_s ∝ |Δ|² (n − Φ/Φ0) (sign: anticlockwise > 0)
  const Is = D['Φ'].map((f, i) => D['Δ'][i] ** 2 * (Math.round(f) - f));
  const Imax = d3.max(D['Φ'].map((f, i) => (f >= 0 && f <= 2.5 ? Math.abs(Is[i]) : 0)));

  // ---------------------------------------------------------------- ring (left)
  const size = 268, R = 84, c = size / 2, ry = 110;
  const ring = QM.panel(el, { x: 0, y: ry, w: size, h: size, m: { l: 0, r: 0, t: 0, b: 0 } });
  ring.g.append('circle').attr('cx', c).attr('cy', c).attr('r', R).attr('fill', 'none')
    .attr('stroke', '#B8C7F9').attr('stroke-width', 30);
  // phase of Δ e^{inφ} at 12 points of the shell: going once around, the arrows turn n times
  const arrows = d3.range(12).map((k) => {
    const phi = (2 * Math.PI * k) / 12;
    return ring.g.append('g').attr('transform', `translate(${c + R * Math.cos(phi)},${c - R * Math.sin(phi)})`)
      .append('path').attr('d', 'M-11,0 H5 M12,0 L2,-6 V6 Z').attr('stroke', C.ink).attr('stroke-width', 3)
      .attr('fill', C.ink).attr('stroke-linejoin', 'round').datum(phi);
  });
  // supercurrent: two curved arrows spinning around the shell, sense = sign of I_s, speed ∝ |I_s|
  const Rc = R + 30, span = 1.9, T1 = 1400;      // arc length (rad); period at the largest |I_s| (ms)
  const cur = ring.g.append('g');
  const arcs = [0, 1].map(() => ({ arc: cur.append('path').attr('fill', 'none').attr('stroke', C.navy)
    .attr('stroke-width', 5).attr('stroke-linecap', 'round'), head: cur.append('path').attr('fill', C.navy) }));
  const iLab = ring.label(size - 4, 14, 'I_\\mathrm{s}', { ax: 1, ay: 0, color: C.navy });
  const nLab = QM.box(el, 0, ry + c - 18, size, 36);
  nLab.className = 'qm-box qm-nlabel';
  const ringCap = QM.box(el, 0, ry + size + 6, size, 30);
  ringCap.className = 'qm-box qm-ringcap';
  QM.tex(ringCap, '\\arg\\Delta = n\\varphi');
  let nNow = null, iNow = 0, theta = 0;
  const pt = (ph, r = Rc) => [c + r * Math.cos(ph), c - r * Math.sin(ph)];
  const drawCurrent = () => {
    const s = Math.sign(iNow) || 1, on = Math.abs(iNow) >= 0.03;
    arcs.forEach(({ arc, head }, k) => {
      const p0 = theta + k * Math.PI, p1 = p0 + s * span;
      arc.attr('d', `M${pt(p0)} A${Rc},${Rc} 0 0,${s > 0 ? 0 : 1} ${pt(p1)}`);
      const tip = pt(p1 + s * 0.2), b = pt(p1);
      head.attr('d', `M${tip} L${b[0] - 8 * Math.cos(p1)},${b[1] + 8 * Math.sin(p1)} L${b[0] + 8 * Math.cos(p1)},${b[1] - 8 * Math.sin(p1)} Z`);
    });
    cur.style('opacity', on ? 1 : 0);
    iLab.style.opacity = on ? 1 : 0;
  };
  const drawRing = (f) => {
    const n = Math.round(f);
    arrows.forEach((a) => a.attr('transform', `rotate(${(-180 / Math.PI) * n * a.datum()})`));
    if (n !== nNow) { QM.tex(nLab, `n = ${n}`); nNow = n; }
    iNow = QM.interp(D['Φ'], Is, f) / Imax;
    drawCurrent();
  };
  // the current arrows turn while the slide is on
  let raf = null, tLast = null;
  const loop = (now) => {
    if (tLast !== null) theta = (theta + ((now - tLast) * 2 * Math.PI * iNow) / T1) % (2 * Math.PI);
    tLast = now;
    drawCurrent();
    raf = requestAnimationFrame(loop);
  };
  const play = () => { if (raf === null) { tLast = null; raf = requestAnimationFrame(loop); } };
  const pause = () => { if (raf !== null) cancelAnimationFrame(raf); raf = null; };

  // ---------------------------------------------------------------- E(Φ): one parabola per n
  const e = QM.panel(el, { x: size + 40, y: 0, w: 640, h: 200, m: { l: 74, r: 14, t: 44, b: 8 } });
  const X = d3.scaleLinear([0, 2.5], [0, e.iw]);
  const YE = d3.scaleLinear([0, 0.42], [e.ih, 0]);
  const fs = d3.range(0, 2.5001, 0.005);
  const clipId = 'lpclip' + Math.random().toString(36).slice(2);
  e.svg.append('defs').append('clipPath').attr('id', clipId).append('rect').attr('width', e.iw).attr('height', e.ih);
  const parab = d3.line().x((d) => X(d[0])).y((d) => YE(d[1]));
  [0, 1, 2, 3].forEach((n) => e.g.append('path').attr('clip-path', `url(#${clipId})`)
    .attr('d', parab(fs.map((f) => [f, (n - f) ** 2]))).attr('fill', 'none')
    .attr('stroke', C.muted).attr('stroke-width', 1.5).attr('stroke-dasharray', '5 5'));
  const env = fs.map((f) => [f, (Math.round(f) - f) ** 2]);
  e.g.append('path').attr('d', d3.area().x((d) => X(d[0])).y0(e.ih).y1((d) => YE(d[1]))(env))
    .attr('fill', C.navy_tint);
  e.g.append('path').attr('d', parab(env)).attr('fill', 'none').attr('stroke', C.navy).attr('stroke-width', 2.8);
  [0.5, 1.5].forEach((f) => e.g.append('line').attr('x1', X(f)).attr('x2', X(f)).attr('y2', e.ih)
    .attr('stroke', C.muted).attr('stroke-dasharray', '5 5').attr('stroke-width', 1.5));
  QM.axis(e, 'bottom', X, { ticks: [0, 0.5, 1, 1.5, 2, 2.5], labels: false });
  QM.frame(e);
  e.label(-24, e.ih / 2, 'E_I', { color: C.navy }).style.transform = 'translate(-50%,-50%) rotate(-90deg)';
  [[0.25, 'n = 0'], [1, 'n = 1'], [2, 'n = 2']].forEach(([f, t]) => e.label(X(f), -18, t, { math: false, cls: 'text' }));
  e.label(X(1), YE(0.3), 'E_I \\propto I_\\mathrm{s}^2', { color: C.navy });
  const eDot = e.g.append('circle').attr('r', 7).attr('fill', C.red).attr('stroke', '#fff').attr('stroke-width', 2);
  const eLine = e.g.append('line').attr('y2', e.ih).attr('stroke', C.red).attr('stroke-width', 2.2);

  // ---------------------------------------------------------------- Ω(Φ)
  const p = QM.panel(el, { x: size + 40, y: 200, w: 640, h: 300, m: { l: 74, r: 14, t: 12, b: 64 } });
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
  p.label(p.iw - 10, p.ih - 12, 'shell gap', { ax: 1, ay: 1, math: false, cls: 'text' }).style.color = C.ink_2;
  const oddLab = p.label(X(1.2), Y(0.2), 'odd lobe:<br>Majoranas<br>possible', { math: false, cls: 'text' });
  Object.assign(oddLab.style, { color: C.red, fontWeight: 700, textAlign: 'center', lineHeight: 1.15, opacity: 0 });
  oddLab.classList.add('qm-fade');
  const curLine = p.g.append('line').attr('y2', p.ih).attr('stroke', C.red).attr('stroke-width', 2.2);
  const dot = p.g.append('circle').attr('r', 7).attr('fill', C.red).attr('stroke', '#fff').attr('stroke-width', 2);

  const sl = QM.slider(el, { x: size + 40 + 74, y: 512, w: 520, min: 0, max: 2.5, step: 0.005, value: 0,
    tex: '\\Phi/\\Phi_0', fmt: (v) => v.toFixed(2), oninput: (v) => { stop(); draw(v); } });
  function draw(f) {
    drawRing(f);
    curLine.attr('x1', X(f)).attr('x2', X(f));
    eLine.attr('x1', X(f)).attr('x2', X(f));
    dot.attr('cx', X(f)).attr('cy', Y(QM.interp(D['Φ'], D['Ω'], f)));
    eDot.attr('cx', X(f)).attr('cy', YE((Math.round(f) - f) ** 2));
    sl.set(f);
  }
  let stop = () => {};
  // step 1 sweeps lobe 0 (up to just before the jump), step 2 on through lobes 1 and 2; step 3: odd lobe
  const ends = [0, 0.49, 2.4];
  return {
    go(step, animate) {
      stop();
      odd.style('opacity', step >= 3 ? 1 : 0);
      oddLab.style.opacity = step >= 3 ? 1 : 0;
      const to = step >= 3 ? P1 : ends[step];
      if (step === 0 || !animate) { draw(to); return; }
      const from = sl.value;
      if (step === 3) { stop = QM.tween(1200, (t) => draw(QM.lerp(from, to, t))); return; }
      stop = QM.tween(Math.max(600, 1800 * Math.abs(to - from)), (t) => draw(QM.lerp(from, to, t)), null, (t) => t);
    },
    enter() { play(); },
    leave() { stop(); pause(); },
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
  legend.innerHTML = '<span class="sw" style="background:#BECDEB"></span><span><i>m</i><sub>J</sub> ≠ 0 · CdGM analogs · class A</span>' +
    '<span class="sw" style="background:#FF4054"></span><span><i>m</i><sub>J</sub> = 0 · class D</span>';
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

QM.register('fs-maps', (el, opts) => {
  const F = QMD.fs_maps, P = QMD.params, C = QM.c;
  const chis = F.chis.map(String);
  const barsAt = (opts.bars || '1000').split(',').map((v) => v.trim());
  const W = +opts.w || 1440, H = +opts.h || 540, gap = 40, pw = (W - gap) / 2, y0 = 50;
  const m = { l: 84, r: 108, t: 90, b: 64 };
  const X = d3.scaleLinear([0.5, 1.5], [0, pw - m.l - m.r]);
  const w0 = F.ω[0], w1 = F.ω[F.ω.length - 1];
  const Y = d3.scaleLinear([w0, w1], [H - y0 - m.t - m.b, 0]);
  const Pc = P['Φc'];
  const btn = QM.buttons(el, { x: m.l, y: 0, items: chis.map((c) => ({ tex: `\\chi = ${c}\\ \\mathrm{nm}` })),
    onpick: (i) => show(i) });
  Object.assign(btn.el.style, { left: W / 2 + 'px', transform: 'translateX(-50%)' });   // centred over both panels
  const panel = (k, key, title, ticks, cbl) => {
    const p = QM.panel(el, { x: k * (pw + gap), y: y0, w: pw, h: H - y0, m });
    const canv = {};
    chis.forEach((c) => {
      const cv = p.canvas();
      QM.heat(cv, F[key][c]);
      Object.assign(cv.style, { left: X(F['Φ'][0]) + 'px', width: X(F['Φ'][F['Φ'].length - 1]) - X(F['Φ'][0]) + 'px',
        top: Y(w1) + 'px', height: Y(w0) - Y(w1) + 'px', transition: 'opacity 0.6s ease', opacity: 0 });
      canv[c] = cv;
    });
    p.g.append('line').attr('x1', X(Pc)).attr('x2', X(Pc)).attr('y2', p.ih).attr('stroke', C.crit)
      .attr('stroke-width', 2.2).attr('stroke-dasharray', '7 5');
    QM.axis(p, 'bottom', X, { ticks: [0.5, 1, 1.5] });
    QM.axis(p, 'left', Y, { ticks: [-0.1, 0, 0.1] });
    QM.frame(p);
    p.label(X(Pc), p.ih + 14, '\\Phi^\\mathrm{c}', { ay: 0, cls: 'small' }).style.color = C.crit;
    p.label(p.iw / 2, p.ih + 50, '\\Phi/\\Phi_0', {});
    p.label(-60, p.ih / 2, '\\omega/\\Delta_0', {}).style.transform = 'translate(-50%,-50%) rotate(-90deg)';
    [[P['Φ1'], '\\Phi^{(1)}'], [P['Φ2'], '\\Phi^{(2)}']].forEach(([f, t]) => {
      p.g.append('path').attr('d', `M${X(f)},-2 l-7,-11 h14 z`).attr('fill', C.ink);
      p.label(X(f), -16, t, { ay: 1, cls: 'small' });
    });
    const tl = p.label(p.iw / 2, -72, title, { ay: 0.5, math: false, cls: 'text' });
    Object.assign(tl.style, { fontWeight: 600, fontSize: '25px', whiteSpace: 'nowrap', lineHeight: 1 });
    QM.colorbar(p, { x: p.iw + 18, ticks, label: cbl });
    return { p, canv };
  };
  const L = panel(0, 'ldos', 'End <i>m</i><sub>J</sub> = 0 LDOS: what the probe sees', ['0', '1'], 'LDOS (arb. u.)');
  const D = panel(1, 'dos', 'Inside the wire: <i>m</i><sub>J</sub> = 0 DOS', ['0.1', '1'], 'DOS (arb. u.)');
  // MZM below Φ^c and quasi-MZM above it, marked on the DOS where both sit at zero energy
  const bars = D.p.g.append('g').attr('class', 'qm-fade').style('opacity', 0);
  const barLabs = [];
  const bar = (x0, x1, yv, text, below) => {
    bars.append('path').attr('d', `M${X(x0)},${Y(yv)} H${X(x1)} M${X(x0)},${Y(yv) - 6} v12 M${X(x1)},${Y(yv) - 6} v12`)
      .attr('stroke', '#fff').attr('stroke-width', 2.2).attr('fill', 'none');
    const l = D.p.label((X(x0) + X(x1)) / 2, Y(yv) + (below ? 10 : -10), text, { ay: below ? 0 : 1, math: false, cls: 'text' });
    Object.assign(l.style, { color: '#fff', fontWeight: 700, opacity: 0 });
    l.classList.add('qm-fade');
    barLabs.push(l);
  };
  bar(0.505, Pc, 0.018, 'MZM', false);
  bar(Pc, 0.98, -0.018, 'quasi-MZM', true);
  function show(i) {
    const c = chis[i];
    [L, D].forEach(({ canv }) => chis.forEach((k) => { canv[k].style.opacity = k === c ? 1 : 0; }));
    const on = barsAt.includes(c);
    bars.style('opacity', on ? 1 : 0);
    barLabs.forEach((l) => { l.style.opacity = on ? 1 : 0; });
    btn.set(i);
  }
  return { go(step) { show(Math.min(step, chis.length - 1)); } };
});

// 'potential': gate potential inside the grounded shell (Eq. A1), longitudinal cut in units of
// R and χ, and the local chemical potential it leaves for the m_J = 0, m_r = 1 mode.
QM.register('potential', (el, opts) => {
  const G = QMD.phig, M = QMD.muz, C = QM.c;
  const H = +opts.h || 380;
  const p = QM.panel(el, { x: 0, y: 0, w: 760, h: H, m: { l: 70, r: 20, t: 30, b: 64 } });
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
  const q = QM.panel(el, { x: 800, y: 0, w: 560, h: H, m: { l: 70, r: 20, t: 30, b: 64 } });
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
