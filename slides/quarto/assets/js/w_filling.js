// Who fills first. Normal-state subbands at k_z = 0 while μ rises, which is what happens
// walking into the wire from its depleted end (μ(z) grows from 0 to μ_bulk).
//  - Partial shell: spinful subbands vs k_z. All belong to the one class-D Hamiltonian, so the
//    first subband to be filled can already turn topological: no threshold.
//  - Full shell: band bottoms of the first radial mode vs m_j = m_l + s_z, one line per s_z
//    branch, computed (thesis Fig. 4.15(a), QMD.bands; the paper's Fig. 4b was schematic), at
//    ⟨α⟩ = 85 meV nm, where the m_r = 0 wedge exists. The m_J = 0 pair (class D, red) is
//    m_j = −1/2 on both branches, split by the flux; the Topo window lies between its levels.
//    The m_J ≠ 0 sectors (class A, CdGM analogs) fill first: topology needs μ > μ^ts, and the
//    stretch of wire with μ(z) < μ^ts is the trivial skin.
// Hovering or dragging along the wire strip sets z, hence μ(z).
// Steps: 0 empty, 1 μ between band bottom and μ^ts, 2 μ above μ^ts.
QM.register('filling', (el) => {
  const C = QM.c;
  const D = QMD.bands;
  // energies in meV from the band bottom
  const Emin = -0.9, Emax = 7.0;
  const states = D.E.flatMap((Es) => Es.map((E, i) => ({ x: D.mj[i], E, j0: D.mj[i] === -0.5 })))
    .filter((s) => s.E < Emax + 1);
  // μ^ts at the lower m_J = 0 level (for simplicity: the Pfaffian window opens 0.6 meV above it)
  const [mts, highJ0] = d3.extent(states.filter((s) => s.j0), (s) => s.E);
  const bottom = 0;
  // partial shell: spinful subbands (schematic), the first with the same band bottom
  const subs = [bottom, bottom + 2.8, bottom + 6.0];
  const curv = 6;

  // ---------------------------------------------------------------- panels
  const mk = (x, title) => {
    const p = QM.panel(el, { x, y: 0, w: 580, h: 400, m: { l: 70, r: 40, t: 50, b: 46 } });
    const t = p.label(p.iw / 2, -26, title, { math: false });
    Object.assign(t.style, { fontSize: '25px', fontWeight: 600 });
    const id = 'fc' + Math.random().toString(36).slice(2);
    p.svg.append('defs').append('clipPath').attr('id', id).append('rect').attr('width', p.iw).attr('height', p.ih);
    p.clipped = p.g.append('g').attr('clip-path', `url(#${id})`);
    return p;
  };
  const A = mk(0, 'Partial shell'), B = mk(720, 'Full shell');
  const YA = d3.scaleLinear([Emin, Emax], [A.ih, 0]), YB = d3.scaleLinear([Emin, Emax], [B.ih, 0]);
  const XA = d3.scaleLinear([-1, 1], [0, A.iw]), XB = d3.scaleLinear([-6.2, 6.2], [0, B.iw]);
  // Topo window between the m_J = 0 levels (full shell)
  const win = B.clipped.append('rect').attr('x', 0).attr('width', B.iw).attr('y', YB(highJ0))
    .attr('height', YB(mts) - YB(highJ0)).attr('fill', C.topo_tint).attr('class', 'qm-fade').style('opacity', 0);
  // skin band (full shell)
  const skin = B.clipped.append('rect').attr('x', 0).attr('width', B.iw).attr('y', YB(mts)).attr('height', YB(bottom) - YB(mts))
    .attr('fill', C.skin_tint).attr('class', 'qm-fade').style('opacity', 0);
  const skinLab = B.label(B.iw / 2, YB(bottom) + 8, 'Trivial skin', { ay: 0, math: false, cls: 'text' });
  Object.assign(skinLab.style, { color: C.green, fontWeight: 700, fontSize: '22px', opacity: 0 });
  skinLab.classList.add('qm-fade');
  // partial-shell parabolas
  const kk = d3.range(-1.1, 1.1001, 0.01);
  const subPaths = subs.map((e0) => {
    A.clipped.append('path').attr('fill', 'none').attr('stroke', C.faint).attr('stroke-width', 2.4)
      .attr('d', d3.line().x((k) => XA(k)).y((k) => YA(e0 + curv * k * k))(kk));
    const filled = A.clipped.append('path').attr('fill', 'none').attr('stroke', C.red).attr('stroke-width', 5)
      .attr('stroke-linecap', 'round');
    return { e0, filled };
  });
  // full-shell bands, one line per s_z branch, and states
  D.E.forEach((Es) => B.clipped.append('path').attr('fill', 'none').attr('stroke', C.faint).attr('stroke-width', 2.4)
    .attr('d', d3.line().x((p) => XB(p[0])).y((p) => YB(p[1]))(Es.map((E, i) => [D.mj[i], E]))));
  const dots = B.clipped.selectAll('circle').data(states).join('circle')
    .attr('cx', (d) => XB(d.x)).attr('cy', (d) => YB(d.E)).attr('r', (d) => (d.j0 ? 11 : 9))
    .attr('stroke-width', 2.5);
  B.label(XB(-0.5) - 16, YB(highJ0) - 4, 'm_J = 0', { ax: 1, ay: 1, color: C.red });
  B.label(XB(3.4), YB(6.0), 'CdGM analogs', { math: false, cls: 'text' }).style.color = C.ink_2;
  // μ lines, labelled outside the frames
  const muA = A.clipped.append('line').attr('x2', A.iw).attr('stroke', C.ink).attr('stroke-width', 2).attr('stroke-dasharray', '7 5');
  const muB = B.clipped.append('line').attr('x2', B.iw).attr('stroke', C.ink).attr('stroke-width', 2).attr('stroke-dasharray', '7 5');
  const muLabA = A.label(A.iw + 8, 0, '\\mu', { ax: 0 });
  const muLabB = B.label(B.iw + 8, 0, '\\mu', { ax: 0 });
  B.label(-10, YB(mts), '\\mu^\\mathrm{ts}', { ax: 1, cls: 'small', color: C.green });
  B.g.append('line').attr('x2', B.iw).attr('y1', YB(mts)).attr('y2', YB(mts)).attr('stroke', C.green).attr('stroke-width', 1.5);
  [A, B].forEach((p) => { QM.frame(p); });
  A.label(A.iw / 2, A.ih + 26, 'k_z', {});
  QM.axis(B, 'bottom', XB, { ticks: d3.range(-5.5, 5.6, 1),
    fmt: (v) => ([1.5, 3.5, 5.5].includes(Math.abs(v)) ? (v < 0 ? '−' : '') + (2 * Math.abs(v)) + '/2' : '') });
  B.label(B.iw / 2, B.ih + 26, 'm_j', {});
  A.label(-30, A.ih * 0.7, 'E', {});
  B.label(-30, B.ih * 0.7, 'E', {});
  // verdicts
  const vA = QM.box(el, 70, 408, 500, 40); vA.className = 'qm-box qm-verdict';
  const vB = QM.box(el, 790, 408, 520, 40); vB.className = 'qm-box qm-verdict';

  // ---------------------------------------------------------------- the wire
  const W = QM.panel(el, { x: 0, y: 466, w: 1340, h: 130, m: { l: 70, r: 40, t: 8, b: 40 } });
  const zx = d3.scaleLinear([0, 6], [0, W.iw]);
  const rowA = W.g.append('g'), rowB = W.g.append('g');
  W.label(-12, 21, 'partial', { ax: 1, math: false, cls: 'text' });
  W.label(-12, 59, 'full', { ax: 1, math: false, cls: 'text' });
  const zMark = W.g.append('line').attr('y1', -4).attr('y2', 80).attr('stroke', C.ink).attr('stroke-width', 3);
  const zKnob = W.g.append('circle').attr('cy', -4).attr('r', 7).attr('fill', C.ink);
  W.label(W.iw / 2, 98, '\\text{walk into the wire: } \\mu(z) \\text{ rises} \\;\\longrightarrow', { cls: 'small' }).style.color = C.muted;
  // μ(z) for the strip: μ_top (1 − e^{−z}) with μ_top above everything shown
  const muTop = 4.6;   // μ_bulk inside the Topo window
  const muOfZ = (z) => Emin + (muTop - Emin) * (1 - Math.exp(-z / 1.4));
  const zOfMu = (m) => -1.4 * Math.log(1 - (m - Emin) / (muTop - Emin));
  const strip = (row, y, phaseOf) => {
    const zs = d3.range(0, 6.0001, 0.02);
    const ph = zs.map((z) => phaseOf(muOfZ(z)));
    let s0 = 0;
    for (let i = 1; i <= zs.length; i++) {
      if (i === zs.length || ph[i] !== ph[s0]) {
        const col = { ins: C.ins, skin: C.skin_tint, topo: C.topo_tint }[ph[s0]];
        row.append('rect').attr('x', zx(zs[s0])).attr('y', y).attr('height', 30)
          .attr('width', zx(i === zs.length ? 6 : zs[i]) - zx(zs[s0]) + 0.5).attr('fill', col);
        s0 = i;
      }
    }
  };
  strip(rowA, 6, (m) => (m < bottom ? 'ins' : 'topo'));
  strip(rowB, 44, (m) => (m < bottom ? 'ins' : m < mts ? 'skin' : 'topo'));
  const zt = (m) => (m <= Emin ? 0 : Math.min(6, zOfMu(m)));
  const sk0 = zt(bottom), sk1 = zt(mts);
  const sl = W.label((zx(sk0) + zx(sk1)) / 2, 59, 'skin', { math: false, cls: 'text' });
  Object.assign(sl.style, { color: C.green, fontWeight: 700 });

  let cur = Emin;
  function draw(mu) {
    cur = mu;
    muA.attr('y1', YA(mu)).attr('y2', YA(mu));
    muB.attr('y1', YB(mu)).attr('y2', YB(mu));
    muLabA.style.top = A.m.t + YA(mu) + 'px';
    muLabB.style.top = B.m.t + YB(mu) + 'px';
    subPaths.forEach(({ e0, filled }) => {
      if (mu <= e0) { filled.attr('d', null); return; }
      const kf = Math.sqrt((mu - e0) / curv);
      const ks = d3.range(-kf, kf + 1e-9, kf / 40);
      filled.attr('d', d3.line().x((k) => XA(k)).y((k) => YA(e0 + curv * k * k))(ks));
    });
    dots.attr('fill', (d) => (d.E < mu ? (d.j0 ? C.red : C.ink_2) : '#fff'))
      .attr('stroke', (d) => (d.j0 ? C.red : C.ink_2));
    const nA = subs.filter((e) => mu > e).length;
    vA.innerHTML = nA ? '<b class="red">class D</b>: the first filled subband can already turn topological' : 'empty: insulating end';
    const anyCdGM = states.some((s) => !s.j0 && s.E < mu), j0 = mu > mts;
    vB.innerHTML = j0 ? '<b class="red">μ between the m<sub>J</sub> = 0 levels</b> (class D): topological'
      : anyCdGM ? '<b>class-A</b> sectors fill first: trivial, <b class="green">skin</b>' : 'empty: insulating end';
    win.style('opacity', j0 ? 1 : 0);
    skin.style('opacity', mu > bottom ? 1 : 0);
    skinLab.style.opacity = mu > bottom ? 1 : 0;
    const z = zt(mu);
    zMark.attr('x1', zx(z)).attr('x2', zx(z));
    zKnob.attr('cx', zx(z));
  }

  // the strip is the control
  const hit = W.g.append('rect').attr('y', -10).attr('width', W.iw).attr('height', 90).attr('fill', 'transparent')
    .style('cursor', 'ew-resize');
  hit.on('pointermove', (ev) => { stop(); const [px] = d3.pointer(ev); draw(muOfZ(QM.clamp(zx.invert(px), 0, 6))); });

  let stop = () => {};
  const presets = [Emin + 0.2, 2.6, 4.45];
  return {
    go(step, animate) {
      stop();
      const target = presets[Math.min(step, 2)];
      if (!animate) { draw(target); return; }
      const from = cur;
      stop = QM.tween(1600, (t) => draw(QM.lerp(from, target, t)));
    },
    leave() { stop(); },
  };
});
