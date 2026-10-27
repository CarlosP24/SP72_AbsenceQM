// Quasi-Majorana pair of the partial shell at V_Z^(2) while the end gets smoother. Left: the
// signed amplitudes (largest spinor component) over their envelopes: Ψ_L oscillates with the
// Fermi wavelength at the hard end, Ψ_R is a smooth bump at the soft edge of the island, and
// the envelopes keep overlapping. Top right: the momentum content of Ψ_R, |Ψ_R(k)|²
// (normalised to its maximum), and its weight at Ψ_L's wavevector k_F (dot), which falls by
// eight decades: Ψ_R stops oscillating like Ψ_L. Bottom right: the splitting E(χ) falls
// exponentially while the spatial overlap Σ√(ρ_L ρ_R) barely changes: the pair is pinned
// because a smooth end cannot couple the two (Kells et al. 2012, Vuik et al. 2019), not
// because they are far apart. Illustrative χ sweep (julia/calc_qmzm_amp_sweep.jl), blended
// between neighbouring χ; E(χ): the split end-LDOS peak (paper Fig. 2b data) for small χ and
// the lowest pole of the closed wire (data/E_QMZM) where that state is localised.
// Steps: 0 χ = 50 nm, 1 sweep up to χ = 400 nm.
QM.register('qmzm', (el) => {
  const P = QMD.params, Q = QMD.qmzm_chi, A = QMD.qmzm_amp, C = QM.c;
  const frames = A.frames, lchi = frames.map((f) => Math.log10(f.χ));
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
  const overlap = frames.map((f) => [f.χ, f.overlap]);

  // ---------------------------------------------------------------- strip
  const S = QM.panel(el, { x: 0, y: 0, w: 820, h: 410, m: { l: 30, r: 16, t: 46, b: 56 } });
  const zx = d3.scaleLinear([-150, zMax], [0, S.iw]);
  const sy = d3.scaleLinear([-0.06, 2.0], [S.ih, 0]);
  const yMu = 1.35, y0 = 0.5, amp = 0.42;           // μ line; baseline and half-height of the amplitudes
  const gReg = S.g.append('g');
  gReg.append('rect').attr('x', 0).attr('width', zx(0)).attr('height', S.ih).attr('fill', C.ins);
  const topo = gReg.append('rect').attr('x', zx(0)).attr('height', S.ih).attr('fill', C.topo_tint);
  const triv = gReg.append('rect').attr('height', S.ih).attr('fill', C.triv);
  const labTopo = S.label(0, sy(1.9), 'Topological', { math: false, cls: 'text' });
  const labTriv = S.label(0, sy(1.9), 'Trivial', { math: false, cls: 'text' });
  const ec = S.g.append('path').attr('fill', 'none').attr('stroke', C.ink).attr('stroke-width', 3);
  S.g.append('line').attr('x1', 0).attr('x2', S.iw).attr('y1', sy(yMu)).attr('y2', sy(yMu))
    .attr('stroke', C.muted).attr('stroke-dasharray', '7 5').attr('stroke-width', 2);
  S.label(S.iw - 6, sy(yMu) + 4, '\\mu', { ax: 1, ay: 0 }).style.color = C.muted;
  // envelopes (where each state lives), then the signed amplitudes on a common baseline
  const envR = S.g.append('path').attr('fill', C.orange).attr('fill-opacity', 0.16);
  const envL = S.g.append('path').attr('fill', C.navy).attr('fill-opacity', 0.14);
  S.g.append('line').attr('x1', zx(0)).attr('x2', S.iw).attr('y1', sy(y0)).attr('y2', sy(y0))
    .attr('stroke', C.ink_2).attr('stroke-opacity', 0.4).attr('stroke-width', 1);
  const pR = S.g.append('path').attr('fill', 'none').attr('stroke', C.orange).attr('stroke-width', 3.2);
  const pL = S.g.append('path').attr('fill', 'none').attr('stroke', C.navy).attr('stroke-width', 2.6);
  // the Fermi wavelength of Ψ_L, marked under its first lobes
  const lam = S.g.append('path').attr('fill', 'none').attr('stroke', C.navy).attr('stroke-width', 1.8);
  const lamLab = S.label(0, sy(y0 + amp + 0.04) - 4, '\\lambda_\\mathrm{F}', { ay: 1, cls: 'small', color: C.navy });
  const yLabL = 1.08, yLabR = 1.0;
  const zClearL = QM.zClear(QMD.muz.z, QMD.muz.Ec_partial, (yLabL - 0.3) / yMu);
  const lL = S.label(0, sy(yLabL), '\\Psi_\\mathrm{L}', { ax: 0, cls: 'big', color: C.navy });
  const lR = S.label(0, sy(yLabR), '\\Psi_\\mathrm{R}', { ax: 0, cls: 'big', color: C.orange });
  QM.axis(S, 'bottom', zx, { ticks: [0, 400, 800, 1200] });
  S.g.append('line').attr('x2', S.iw).attr('y1', S.ih).attr('y2', S.ih).attr('stroke', C.ink).attr('stroke-width', 1.3);
  S.label(zx(1400), S.ih + 22, 'z\\ (\\mathrm{nm})', { ay: 0 });
  const chiLab = S.label(S.iw, -24, '', { ax: 1, cls: 'big' });

  // ---------------------------------------------------------------- |Ψ(k)|²
  const K = QM.panel(el, { x: 860, y: 0, w: 580, h: 200, m: { l: 92, r: 18, t: 30, b: 46 } });
  const kx = d3.scaleLinear([0, 0.1], [0, K.iw]);
  const ky = d3.scaleLinear([-11, 0.4], [K.ih, 0]);        // log10 |Ψ_R(k)|²
  const kClip = 'kc' + Math.random().toString(36).slice(2);
  K.svg.append('defs').append('clipPath').attr('id', kClip).append('rect').attr('width', K.iw).attr('height', K.ih);
  const kF = K.g.append('line').attr('y2', K.ih).attr('stroke', C.navy).attr('stroke-dasharray', '5 4').attr('stroke-width', 1.6);
  const kFLab = K.label(0, -6, 'k_\\mathrm{F}\\ (\\Psi_\\mathrm{L})', { ay: 1, cls: 'small', color: C.navy });
  const kR = K.g.append('path').attr('clip-path', `url(#${kClip})`).attr('fill', 'none').attr('stroke', C.orange).attr('stroke-width', 2.8);
  QM.axis(K, 'bottom', kx, { ticks: [0, 0.05, 0.1], fmt: (v) => (v ? v.toFixed(2) : '0') });
  const kDot = K.g.append('circle').attr('r', 6.5).attr('fill', C.orange).attr('stroke', '#fff').attr('stroke-width', 2);
  const kVal = K.label(0, 0, '', { ax: 0, ay: 0.5, cls: 'small', color: C.orange });
  QM.axis(K, 'left', ky, { ticks: [-10, -5, 0], fmt: () => '' });
  [[-10, '10^{-10}'], [-5, '10^{-5}'], [0, '1']].forEach(([v, t]) => K.label(-12, ky(v), t, { ax: 1, cls: 'small' }));
  QM.frame(K);
  K.label(K.iw - 10, 10, 'k_\\mathrm{F} = 2\\pi/\\lambda_\\mathrm{F}', { ax: 1, ay: 0, cls: 'small', color: C.navy });
  K.label(kx(0.08), K.ih + 22, 'k\\ (\\mathrm{nm}^{-1})', { ay: 0, cls: 'small' });
  K.label(-70, K.ih / 2, '|\\Psi_\\mathrm{R}(k)|^2', { cls: 'small' }).style.transform = 'translate(-50%,-50%) rotate(-90deg)';

  // ---------------------------------------------------------------- E(χ) and overlap
  const G = QM.panel(el, { x: 860, y: 222, w: 580, h: 236, m: { l: 92, r: 18, t: 16, b: 50 } });
  const X = d3.scaleLog([10, 1000], [0, G.iw]);
  const Y = d3.scaleLog([1e-5, 1], [G.ih, 0]);
  const clip = 'qc' + Math.random().toString(36).slice(2);
  G.svg.append('defs').append('clipPath').attr('id', clip).append('rect').attr('width', G.iw).attr('height', G.ih);
  const ln = d3.line().x((d) => X(d[0])).y((d) => Y(d[1]));
  G.g.append('path').attr('clip-path', `url(#${clip})`).attr('fill', 'none').attr('stroke', C.navy)
    .attr('stroke-width', 2.6).attr('stroke-dasharray', '8 5').attr('d', ln(overlap));
  G.g.append('path').attr('clip-path', `url(#${clip})`).attr('fill', 'none').attr('stroke', C.ink)
    .attr('stroke-width', 2.6).attr('d', ln(Ecurve));
  QM.axis(G, 'bottom', X, { ticks: [10, 100, 1000], fmt: d3.format('d') });
  QM.axis(G, 'left', Y, { ticks: [1e-5, 1e-4, 1e-3, 1e-2, 1e-1, 1], fmt: () => '' });
  [[-5, 1e-5], [-3, 1e-3], [-1, 1e-1]].forEach(([e, v]) => G.label(-12, Y(v), `10^{${e}}`, { ax: 1, cls: 'small' }));
  G.label(-12, Y(1), '1', { ax: 1, math: false, cls: 'text' });
  QM.frame(G);
  G.label(G.iw / 2, G.ih + 40, '\\chi\\ (\\mathrm{nm})', { cls: 'small' });
  const lo = G.label(X(430), Y(0.11), 'overlap', { ax: 0, ay: 0.5, math: false, cls: 'text' });
  Object.assign(lo.style, { color: C.navy, fontSize: '18px' });
  const le = G.label(X(13), Y(1e-3), 'splitting <i>E</i>/Δ<sub>0</sub>', { ax: 0, ay: 0.5, math: false, cls: 'text' });
  Object.assign(le.style, { color: C.ink, fontSize: '18px' });
  const oDot = G.g.append('circle').attr('r', 7).attr('fill', C.navy).attr('stroke', '#fff').attr('stroke-width', 2.2);
  const eDot = G.g.append('circle').attr('r', 7).attr('fill', C.orange).attr('stroke', '#fff').attr('stroke-width', 2.2);

  // ---------------------------------------------------------------- controls
  const sl = QM.slider(el, { x: 30, y: 420, w: 520, min: Math.log10(20), max: Math.log10(400), step: Math.log10(20) / 260,   // range/260: the last step is 400
    value: Math.log10(50), tex: '\\chi', fmt: (v) => `${Math.round(Math.pow(10, v))} nm`,
    oninput: (v) => { stop(); draw(v); } });
  const play = document.createElement('button');
  play.className = 'qm-play'; play.textContent = '▶ play';
  const pb = QM.box(el, 580, 424, 100, 34); pb.appendChild(play);
  play.addEventListener('click', () => { play.blur(); sweep(Math.log10(20), Math.log10(400), 3000); });

  // ---------------------------------------------------------------- drawing
  const z = A.z, ks = A.k;
  const Ec0 = QMD.muz.Ec_partial, zc = QMD.muz.z;
  const inZ = (j) => z[j] <= zMax;
  function draw(lc) {
    const chi = Math.pow(10, lc);
    let i = 0;
    while (i < frames.length - 2 && lchi[i + 1] <= lc) i++;
    const t = QM.clamp((lc - lchi[i]) / (lchi[i + 1] - lchi[i]), 0, 1);
    const blend = (k) => frames[i][k].map((v, j) => (1 - t) * v + t * frames[i + 1][k][j]);
    const fL = blend('L'), fR = blend('R'), gL = blend('eL'), gR = blend('eR');
    const curve = (arr) => d3.line().x((v, j) => zx(z[j])).y((v) => sy(y0 + amp * v))(arr.filter((v, j) => inZ(j)));
    const band = (env) => d3.area().x((v, j) => zx(z[j])).y0((v) => sy(y0 - amp * v)).y1((v) => sy(y0 + amp * v))(env.filter((v, j) => inZ(j)));
    pL.attr('d', curve(fL)); pR.attr('d', curve(fR));
    envL.attr('d', band(gL)); envR.attr('d', band(gR));
    // phases along the wire and the band bottom
    const zt = P.zP_topo_end * chi;
    topo.attr('width', zx(zt) - zx(0));
    triv.attr('x', zx(zt)).attr('width', Math.max(0, S.iw - zx(zt)));
    labTopo.style.left = S.m.l + (zx(0) + zx(zt)) / 2 + 'px';
    labTopo.style.opacity = zx(zt) - zx(0) > 140 ? 1 : 0;
    labTriv.style.left = S.m.l + (zx(zt) + S.iw) / 2 + 'px';
    const pts = zc.map((zz, k) => [zz < 0 ? 150 * zz : zz * chi, Ec0[k]]).filter((d) => d[0] <= zMax);
    if (pts[pts.length - 1][0] < zMax) pts.push([zMax, pts[pts.length - 1][1]]);   // flat bulk beyond the data
    ec.attr('d', d3.line().x((d) => zx(d[0])).y((d) => sy(Math.min(yMu * d[1], 1.98)))(pts));
    // labels: Ψ_L over its first lobe (clear of the band bottom), Ψ_R right of its peak
    const iL = gL.indexOf(d3.max(gL)), iR = gR.indexOf(d3.max(gR));
    let jR = iR;
    while (jR < gR.length - 1 && gR[jR] > 0.55) jR++;
    lR.style.left = S.m.l + Math.min(zx(z[jR]) + 8, S.iw - 60) + 'px';
    // momentum content
    const kLi = blend('kL'), kRi = blend('kR');
    kR.attr('d', d3.line().x((v, j) => kx(ks[j])).y((v) => ky(Math.max(v, -12)))(kRi));
    const jF = kLi.indexOf(d3.max(kLi)), kFv = ks[jF];
    kF.attr('x1', kx(kFv)).attr('x2', kx(kFv));
    kFLab.style.left = K.m.l + kx(kFv) + 'px';
    kDot.attr('cx', kx(kFv)).attr('cy', ky(Math.max(kRi[jF], -11)));
    kVal.style.left = K.m.l + kx(kFv) + 12 + 'px'; kVal.style.top = K.m.t + ky(Math.max(kRi[jF], -11)) - 14 + 'px';
    QM.tex(kVal, `10^{${Math.round(kRi[jF])}}`);
    // λ_F bracket from the first maximum of Ψ_L
    const lamF = (2 * Math.PI) / kFv;
    let j0 = 1;
    while (j0 < fL.length - 1 && !(fL[j0] >= fL[j0 - 1] && fL[j0] >= fL[j0 + 1] && fL[j0] > 0.3)) j0++;
    // above the first lobes, unless the band bottom passes there (smooth ends): then below them,
    // labelled to the right of the bracket
    const zA = z[j0], zB = zA + lamF, yUp = y0 + amp + 0.04;
    const bandAt = (zz) => yMu * QM.interp(zc.map((v) => v * chi), Ec0, zz);
    const clash = [zA, (zA + zB) / 2, zB].some((zz) => Math.abs(bandAt(zz) - (yUp + 0.08)) < 0.14);
    const xa = zx(zA), xb = zx(zB);
    if (!clash) {
      const yb = sy(yUp);
      lam.attr('d', `M${xa},${yb + 6} V${yb} H${xb} V${yb + 6}`);
      Object.assign(lamLab.style, { left: S.m.l + (xa + xb) / 2 + 'px', top: S.m.t + yb - 4 + 'px', transform: 'translate(-50%,-100%)' });
    } else {
      const yb = sy(y0 - amp - 0.03);
      lam.attr('d', `M${xa},${yb - 6} V${yb} H${xb} V${yb - 6}`);
      Object.assign(lamLab.style, { left: S.m.l + xb + 6 + 'px', top: S.m.t + yb + 'px', transform: 'translate(0,-50%)' });
    }
    lL.style.left = S.m.l + Math.max(zx(zClearL * chi), zx(z[iL]) + 14, xb + 14) + 'px';
    // E and overlap at this χ
    QM.tex(chiLab, `\\chi = ${Math.round(chi)}\\ \\mathrm{nm}`);
    const e = Eat(chi), o = QM.interp(overlap.map((d) => Math.log10(d[0])), overlap.map((d) => d[1]), lc);
    eDot.attr('cx', X(chi)).attr('cy', Y(QM.clamp(e, 1e-5, 1)));
    oDot.attr('cx', X(chi)).attr('cy', Y(o));
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
      sweep(sl.value, Math.log10(400), 2500);
    },
    leave() { stop(); },
  };
});
