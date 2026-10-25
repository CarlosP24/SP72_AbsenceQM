// Quasi-Majorana pair of the partial shell at V_Z^(2) while the end gets smoother: the
// topological island (z < 1.86χ) grows, Ψ_R moves away from Ψ_L and the splitting E(χ)
// falls exponentially. Densities from the illustrative χ sweep (julia/calc_partial_sweeps.jl),
// blended between neighbouring χ; E(χ): the split end-LDOS peak (paper Fig. 2b data) for
// small χ and the lowest pole of the closed wire (data/E_QMZM) where that state is localised.
// Steps: 0 χ = 50 nm, 1 sweep up to χ = 400 nm.
QM.register('qmzm', (el) => {
  const P = QMD.params, Q = QMD.qmzm_chi, C = QM.c;
  const frames = Q.frames, lchi = frames.map((f) => Math.log10(f.χ));
  const zMax = 1500;

  // ---------------------------------------------------------------- E(χ)
  // split peak of the end LDOS (ω > 0) for each χ, then the pole energy where available
  const L = QMD.ldos_chi, mp = L.maps.partial_QMajo, a = QM.u8(mp);
  const iw0 = L.ω.findIndex((w) => w > 1e-9);
  const ldosE = L.χ.map((chi, i) => {
    let best = iw0, bv = -1;
    for (let j = iw0; j < mp.ny; j++) { const v = a[i + mp.nx * j]; if (v > bv) { bv = v; best = j; } }
    return [chi, L.ω[best]];
  }).filter(([chi, e]) => chi < 75 && e > 0.003);
  // pole energies until they leave the log axis (beyond, the closed wire is numerically at zero)
  let poleE = Q.E.χ.map((chi, i) => [chi, Q.E.E[i]]).filter(([chi]) => chi >= 75);
  const kf = poleE.findIndex(([, e]) => !(e > 1e-7));
  if (kf >= 0) poleE = poleE.slice(0, kf);
  const Ecurve = ldosE.concat(poleE);
  const Eat = (chi) => {
    const xs = Ecurve.map((d) => Math.log10(d[0])), ys = Ecurve.map((d) => Math.log10(d[1]));
    return Math.pow(10, QM.interp(xs, ys, Math.log10(chi)));
  };

  // ---------------------------------------------------------------- strip
  const S = QM.panel(el, { x: 0, y: 0, w: 900, h: 410, m: { l: 30, r: 20, t: 46, b: 56 } });
  const zx = d3.scaleLinear([-150, zMax], [0, S.iw]);
  const sy = d3.scaleLinear([-0.06, 2.0], [S.ih, 0]);
  const yMu = 1.35;
  const gReg = S.g.append('g');
  const ins = gReg.append('rect').attr('x', 0).attr('width', zx(0)).attr('height', S.ih).attr('fill', C.ins);
  const topo = gReg.append('rect').attr('x', zx(0)).attr('height', S.ih).attr('fill', C.topo_tint);
  const triv = gReg.append('rect').attr('height', S.ih).attr('fill', C.triv);
  const labTopo = S.label(0, sy(1.9), 'Topological', { math: false, cls: 'text' });
  const labTriv = S.label(0, sy(1.9), 'Trivial', { math: false, cls: 'text' });
  const ec = S.g.append('path').attr('fill', 'none').attr('stroke', C.ink).attr('stroke-width', 3);
  S.g.append('line').attr('x1', 0).attr('x2', S.iw).attr('y1', sy(yMu)).attr('y2', sy(yMu))
    .attr('stroke', C.muted).attr('stroke-dasharray', '7 5').attr('stroke-width', 2);
  S.label(S.iw - 6, sy(yMu) + 4, '\\mu', { ax: 1, ay: 0 }).style.color = C.muted;
  const pL = S.g.append('path').attr('fill', 'none').attr('stroke', C.navy).attr('stroke-width', 3);
  const pR = S.g.append('path').attr('fill', 'none').attr('stroke', C.orange).attr('stroke-width', 3.4);
  const lL = S.label(0, sy(0.98), '|\\Psi_\\mathrm{L}|^2', { ax: 0, color: C.navy });
  const lR = S.label(0, sy(0.98), '|\\Psi_\\mathrm{R}|^2', { ax: 0, color: C.orange });
  QM.axis(S, 'bottom', zx, { ticks: [0, 400, 800, 1200] });
  S.g.append('line').attr('x2', S.iw).attr('y1', S.ih).attr('y2', S.ih).attr('stroke', C.ink).attr('stroke-width', 1.3);
  S.label(zx(1400), S.ih + 22, 'z\\ (\\mathrm{nm})', { ay: 0 });
  const chiLab = S.label(S.iw, -24, '', { ax: 1, cls: 'big' });

  // ---------------------------------------------------------------- E(χ) panel
  const G = QM.panel(el, { x: 950, y: 0, w: 490, h: 410, m: { l: 92, r: 18, t: 46, b: 56 } });
  const X = d3.scaleLog([10, 1000], [0, G.iw]);
  const Y = d3.scaleLog([1e-5, 1], [G.ih, 0]);
  const clip = 'qc' + Math.random().toString(36).slice(2);
  G.svg.append('defs').append('clipPath').attr('id', clip).append('rect').attr('width', G.iw).attr('height', G.ih);
  const chiStar = (P['αP'] * P['μbulkP']) / (P.VZ2 * P['Δ0']);
  G.g.append('rect').attr('x', X(chiStar)).attr('width', G.iw - X(chiStar)).attr('height', G.ih)
    .attr('fill', C.red_tint);
  G.g.append('line').attr('x1', X(chiStar)).attr('x2', X(chiStar)).attr('y2', G.ih)
    .attr('stroke', C.red).attr('stroke-dasharray', '6 5').attr('stroke-width', 2);
  G.label(X(chiStar), -10, '\\hbar\\alpha\\mu_\\mathrm{bulk}/V_\\mathrm{Z}\\Delta_0', { ax: 0.5, ay: 1, cls: 'small' }).style.color = C.red;
  G.label(G.iw - 8, 16, 'pinned', { ax: 1, math: false, cls: 'text' }).style.color = C.red;
  G.g.append('path').attr('clip-path', `url(#${clip})`).attr('fill', 'none').attr('stroke', C.ink)
    .attr('stroke-width', 2.6).attr('d', d3.line().x((d) => X(d[0])).y((d) => Y(d[1]))(Ecurve));
  QM.axis(G, 'bottom', X, { ticks: [10, 100, 1000], fmt: d3.format('d') });
  QM.axis(G, 'left', Y, { ticks: [1e-5, 1e-4, 1e-3, 1e-2, 1e-1, 1], fmt: (v) => '' });
  [[-5, 1e-5], [-3, 1e-3], [-1, 1e-1]].forEach(([e, v]) => G.label(-12, Y(v), `10^{${e}}`, { ax: 1, cls: 'small' }));
  G.label(-12, Y(1), '1', { ax: 1, math: false, cls: 'text' });
  QM.frame(G);
  G.label(G.iw / 2, G.ih + 44, '\\chi\\ (\\mathrm{nm})', {});
  G.label(-74, G.ih / 2, 'E/\\Delta_0', {}).style.transform = 'translate(-50%,-50%) rotate(-90deg)';
  const dot = G.g.append('circle').attr('r', 8).attr('fill', C.orange).attr('stroke', '#fff').attr('stroke-width', 2.5);

  // ---------------------------------------------------------------- controls
  const sl = QM.slider(el, { x: 30, y: 420, w: 520, min: Math.log10(20), max: Math.log10(400), step: 0.005,
    value: Math.log10(50), tex: '\\chi', fmt: (v) => `${Math.round(Math.pow(10, v))} nm`,
    oninput: (v) => { stop(); draw(v); } });
  const play = document.createElement('button');
  play.className = 'qm-play'; play.textContent = '▶ play';
  const pb = QM.box(el, 580, 424, 100, 34); pb.appendChild(play);
  play.addEventListener('click', () => { play.blur(); sweep(Math.log10(20), Math.log10(400), 6000); });

  // ---------------------------------------------------------------- drawing
  const z = Q.z;
  const Ec0 = QMD.muz.Ec_partial, zc = QMD.muz.z;
  function draw(lc) {
    const chi = Math.pow(10, lc);
    let i = 0;
    while (i < frames.length - 2 && lchi[i + 1] <= lc) i++;
    const t = QM.clamp((lc - lchi[i]) / (lchi[i + 1] - lchi[i]), 0, 1);
    const blend = (k) => frames[i][k].map((v, j) => (1 - t) * v + t * frames[i + 1][k][j]);
    const dl = blend('L'), dr = blend('R');
    const mxL = d3.max(dl), mxR = d3.max(dr);
    const line = (arr, mx) => d3.line().x((v, j) => zx(z[j])).y((v) => sy((0.9 * v) / mx))(arr.filter((v, j) => z[j] <= zMax));
    pL.attr('d', line(dl, mxL)); pR.attr('d', line(dr, mxR));
    const zt = P.zP_topo_end * chi;
    topo.attr('width', zx(zt) - zx(0));
    triv.attr('x', zx(zt)).attr('width', Math.max(0, S.iw - zx(zt)));
    labTopo.style.left = S.m.l + (zx(0) + zx(zt)) / 2 + 'px';
    labTopo.style.opacity = zx(zt) - zx(0) > 140 ? 1 : 0;
    labTriv.style.left = S.m.l + (zx(zt) + S.iw) / 2 + 'px';
    const pts = zc.map((zz, k) => [zz < 0 ? 150 * zz : zz * chi, Ec0[k]]).filter((d) => d[0] <= zMax);
    ec.attr('d', d3.line().x((d) => zx(d[0])).y((d) => sy(Math.min(yMu * d[1], 1.98)))(pts));
    const iL = dl.indexOf(mxL), iR = dr.indexOf(mxR);
    lL.style.left = S.m.l + zx(z[iL]) + 18 + 'px';
    lR.style.left = S.m.l + Math.min(zx(z[iR]) + 26, S.iw - 70) + 'px';
    lR.style.top = S.m.t + sy(0.8) + 'px';
    QM.tex(chiLab, `\\chi = ${Math.round(chi)}\\ \\mathrm{nm}`);
    const e = Eat(chi);
    dot.attr('cx', X(chi)).attr('cy', Y(QM.clamp(e, 1e-5, 1)));
    sl.set(lc);
  }

  let stop = () => {};
  function sweep(from, to, ms) {
    stop();
    stop = QM.tween(ms, (t) => draw(QM.lerp(from, to, t)));
  }
  return {
    go(step, animate) {
      stop();
      if (step === 0 || !animate) { draw(step === 0 ? Math.log10(50) : Math.log10(400)); return; }
      sweep(sl.value, Math.log10(400), 5000);
    },
    leave() { stop(); },
  };
});
