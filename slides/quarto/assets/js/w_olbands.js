// Oreg–Lutchyn nanowire: BdG bands E(k_z) while V_Z sweeps through V_Z^c, with the
// (V_Z, μ) phase diagram and the Z2 index Q = sign Pf = sign(Δ² + μ² − V_Z²).
// Partial-shell parameters of the paper (μ = 2 meV, α = 40 meV nm, m* = 0.023 m_e) with a
// constant pairing Δ = Δ0, so that V_Z^c = √(Δ² + μ²) holds exactly.
// Steps: 0 V_Z = 0, 1 V_Z = V_Z^c, 2 V_Z = 1.5 V_Z^c.
QM.register('olbands', (el) => {
  const P = QMD.params;
  const D = P['Δ0'], mu = P['μbulkP'], alpha = P['αP'];
  const t0 = 38.0998 / 0.023;                      // ħ²/2m* (meV nm²)
  const Vc = Math.sqrt(D * D + mu * mu);

  // four BdG bands at k
  const bands = (k, V) => {
    const xi = t0 * k * k - mu, ak = alpha * k;
    const a = xi * xi + ak * ak + V * V + D * D;
    const b = 2 * Math.sqrt(V * V * D * D + xi * xi * (V * V + ak * ak));
    const lo = Math.sqrt(Math.max(a - b, 0)), hi = Math.sqrt(a + b);
    return [-hi, -lo, lo, hi];
  };

  // --- band panel
  const p = QM.panel(el, { x: 0, y: 0, w: 540, h: 500, m: { l: 78, r: 16, t: 16, b: 66 } });
  const kmax = 0.07, Emax = 10.5;
  const x = d3.scaleLinear([-kmax, kmax], [0, p.iw]);
  const y = d3.scaleLinear([-Emax, Emax], [p.ih, 0]);
  p.g.append('line').attr('x1', 0).attr('x2', p.iw).attr('y1', y(0)).attr('y2', y(0))
    .attr('stroke', QM.c.line).attr('stroke-width', 1.2);
  QM.axis(p, 'bottom', x, { ticks: [-0.06, -0.03, 0, 0.03, 0.06] });
  QM.axis(p, 'left', y, { ticks: [-10, -5, 0, 5, 10] });
  QM.frame(p);
  p.label(p.iw / 2, p.ih + 52, 'k_z\\ (\\mathrm{nm}^{-1})', { ay: 0.5 });
  p.label(-58, p.ih / 2, 'E/\\Delta_0', { ax: 0.5 }).style.transform = 'translate(-50%,-50%) rotate(-90deg)';

  const ks = d3.range(-kmax, kmax + 1e-9, (2 * kmax) / 600);
  const line = d3.line().x((d) => x(d[0])).y((d) => y(d[1])).defined((d) => Math.abs(d[1]) < Emax + 1);
  const clip = 'clip' + Math.random().toString(36).slice(2);
  p.svg.append('defs').append('clipPath').attr('id', clip).append('rect').attr('width', p.iw).attr('height', p.ih);
  const gb = p.g.append('g').attr('clip-path', `url(#${clip})`);
  const paths = [0, 1, 2, 3].map((i) => gb.append('path').attr('fill', 'none')
    .attr('stroke-width', i === 1 || i === 2 ? 3.2 : 2.2)
    .attr('stroke', i === 1 || i === 2 ? QM.c.ink : QM.c.faint));
  // gap at k = 0: double arrow between ±E(k = 0)
  const gapG = p.g.append('g');
  const gapLine = gapG.append('line').attr('x1', x(0)).attr('x2', x(0)).attr('stroke-width', 2.4);
  const tipUp = gapG.append('path'), tipDn = gapG.append('path');


  // --- phase diagram inset (V_Z/V_Z^c, μ/μ_bulk)
  const q = QM.panel(el, { x: 548, y: 0, w: 260, h: 250, m: { l: 58, r: 10, t: 10, b: 58 } });
  const X = d3.scaleLinear([0, 2], [0, q.iw]);
  const Y = d3.scaleLinear([-0.25, 1.25], [q.ih, 0]);
  q.g.append('rect').attr('width', q.iw).attr('height', q.ih).attr('fill', QM.c.triv);
  const mus = d3.range(-0.25, 1.25 + 1e-9, 0.01);
  const topo = [[2, -0.25], ...mus.map((m) => [Math.sqrt(D * D + (m * mu) ** 2) / Vc, m]), [2, 1.25]]
    .map(([v, m]) => [X(Math.min(v, 2)), Y(m)]);
  q.g.append('path').attr('d', d3.line()(topo) + 'Z').attr('fill', QM.c.topo_tint);
  q.g.append('rect').attr('y', Y(0)).attr('width', q.iw).attr('height', q.ih - Y(0)).attr('fill', QM.c.ins);
  q.g.append('line').attr('x1', 0).attr('x2', q.iw).attr('y1', Y(1)).attr('y2', Y(1))
    .attr('stroke', QM.c.muted).attr('stroke-dasharray', '5 4').attr('stroke-width', 1.4);
  QM.axis(q, 'bottom', X, { ticks: [0, 1, 2] });
  QM.axis(q, 'left', Y, { ticks: [0, 1], fmt: (v) => (v === 0 ? '0' : '') });
  q.label(-10, Y(1), '\\mu_\\mathrm{bulk}', { ax: 1, cls: 'small' });
  QM.frame(q);
  q.label(q.iw / 2, q.ih + 46, 'V_\\mathrm{Z}/V_\\mathrm{Z}^\\mathrm{c}', { cls: 'small' });
  q.label(X(0.4), Y(0.72), 'trivial', { math: false, cls: 'text' }).style.color = QM.c.muted;
  q.label(X(1.42), Y(0.3), 'topological', { math: false, cls: 'text' }).style.color = QM.c.red;
  const dot = q.g.append('circle').attr('r', 8).attr('stroke', '#fff').attr('stroke-width', 2.5);

  // --- Z2 badge
  const badge = QM.box(el, 600, 278, 200, 90);
  badge.className = 'qm-box qm-badge';

  // --- slider
  const sl = QM.slider(el, { x: 78, y: 512, w: 470, min: 0, max: 2, step: 0.01, value: 0,
    tex: 'V_\\mathrm{Z}/V_\\mathrm{Z}^\\mathrm{c}', oninput: (v) => { stop(); draw(v); } });

  function draw(v) {
    const V = v * Vc;
    const data = ks.map((k) => bands(k, V));
    paths.forEach((pa, i) => pa.attr('d', line(data.map((b, j) => [ks[j], b[i] / D]))));
    const g0 = -bands(0, V)[1] / D;                 // E(k = 0) of the low band, in Δ0
    const top = v > 1, closing = Math.abs(v - 1) < 0.03;
    const col = closing ? QM.c.orange : top ? QM.c.red : QM.c.ink_2;
    const show = g0 < Emax - 0.6 && g0 > 0.9;
    gapG.style('opacity', show ? 1 : 0);
    gapLine.attr('y1', y(g0) + 8).attr('y2', y(-g0) - 8).attr('stroke', col);
    tipUp.attr('d', `M${x(0)},${y(g0)} l-6,10 h12 z`).attr('fill', col);
    tipDn.attr('d', `M${x(0)},${y(-g0)} l-6,-10 h12 z`).attr('fill', col);

    dot.attr('cx', X(Math.min(v, 2))).attr('cy', Y(1)).attr('fill', top ? QM.c.red : QM.c.ink_2);
    badge.innerHTML = closing
      ? '<span class="qm-q orange">gap closes</span><span class="qm-q-sub">at k<sub>z</sub> = 0, V<sub>Z</sub> = V<sub>Z</sub><sup>c</sup></span>'
      : top
        ? '<span class="qm-q red">Q = −1</span><span class="qm-q-sub">topological · MZMs at the ends</span>'
        : '<span class="qm-q">Q = +1</span><span class="qm-q-sub">trivial</span>';
    sl.set(v);
  }

  let cur = 0, stop = () => {};
  const presets = [0, 1, 1.5];
  return {
    go(step, animate) {
      const target = presets[Math.min(step, presets.length - 1)];
      stop();
      if (!animate) { cur = target; draw(cur); return; }
      const from = sl.value;
      stop = QM.tween(1400, (t) => { cur = QM.lerp(from, target, t); draw(cur); });
    },
    leave() { stop(); },
  };
});
