// Smooth confinement: μ(z) traces a vertical path through the phase diagram, and the local
// phase along that path colours the wire (paper Fig. 1a, b, d, f). One widget for both
// geometries: data-shell="partial" (V_Z, μ) or "full" (Φ in lobe 1, μ on the schematic
// axis of the poster, 0 → μ^ts compressed, μ^ts → μ_bulk stretched).
// Steps: 0 electrostatics only, 1 MZM case (V_Z^(1) / Φ^(1)), 2 quasi-MZM case.
// Entering step 1 walks into the wire: a gauge between μ and the band bottom (its length is
// the local μ(z)) moves along z, the wire takes its local phase behind it, and the path grows
// up the phase diagram with it. Hovering over the wire marks the point μ(z) on the path.
QM.register('path', (el, opts) => {
  const P = QMD.params;
  const full = opts.shell === 'full';
  const C = QM.c;
  const cProbe = '#B4B4B4', cSemi = '#FBF6CB', cSuper = '#B8C7F9';

  // ---------------------------------------------------------------- geometry
  const zpos = QMD.muz.zpos;
  let cfg;
  if (!full) {
    cfg = {
      xs: QMD.pd_partial.VZ, iv: QMD.pd_partial.iv, xdom: [0, 2], ydom: [-0.22, 1.15],
      Y: (m) => m, presets: [null, P.VZ1 / P.VZc, P.VZ2 / P.VZc], crit: 1,
      critTex: 'V_\\mathrm{Z}^\\mathrm{c}', xTex: 'V_\\mathrm{Z}/V_\\mathrm{Z}^\\mathrm{c}',
      xticks: [0, 1, 2], muz: () => QMD.muz.partial, Ec: () => QMD.muz.Ec_partial, zmax: 6,
      wf: QMD.wfs.partial, pTex: ['V_\\mathrm{Z}^{(1)}', 'V_\\mathrm{Z}^{(2)}'], walkMs: 2300,
    };
  } else {
    // schematic μ axis (slides/make_figs.jl μaxis)
    const mts = QMD.pd_full.μts, w = QMD.pd_full.w;
    const a = 0.5 / mts, b = 0.5 / (1 - mts);
    const raw = (m) => a * m + (b - a) * w * Math.log1p(Math.exp((m - mts) / w));
    const r0 = raw(0), r1 = raw(1);
    cfg = {
      xs: QMD.pd_full.Φ, iv: QMD.pd_full.iv, xdom: [0.5, 1.5], ydom: [-0.2, 1.1],
      Y: (m) => (raw(m) - r0) / (r1 - r0), presets: [null, P['Φ1'], P['Φ2']], crit: P['Φc'],
      critTex: '\\Phi^\\mathrm{c}', xTex: '\\Phi/\\Phi_0', xticks: [0.5, 1, 1.5],
      muz: (x) => (Math.abs(x - P['Φ1']) < Math.abs(x - P['Φ2']) ? QMD.muz.full1 : QMD.muz.full2),
      Ec: (x) => (Math.abs(x - P['Φ1']) < Math.abs(x - P['Φ2']) ? QMD.muz.Ec_full1 : QMD.muz.Ec_full2),
      zmax: 9, wf: QMD.wfs.full, pTex: ['\\Phi^{(1)}', '\\Phi^{(2)}'], walkMs: 2300,
    };
  }

  // topological intervals (μ/μ_bulk) of the phase-diagram column nearest to x, sorted
  cfg.iv.forEach((iv) => iv.sort((a, b) => a[0] - b[0]));
  const ivAt = (x) => cfg.iv[QM.nearest(cfg.xs, x)];
  // local phase at (x, μ): 'ins', 'topo', 'skin' (trivial below the first topological
  // window, full shell only), 'triv'
  const phase = (x, m) => {
    if (m < 0) return 'ins';
    const iv = ivAt(x);
    for (const [a, b] of iv) if (m >= a && m <= b) return 'topo';
    if (full && iv.length && m < iv[0][0] && iv[0][0] < 1) return 'skin';
    return 'triv';
  };
  const fill = { ins: C.ins, topo: C.topo_tint, skin: C.skin_tint, triv: C.triv };
  const ink = { ins: '#555555', topo: C.red, skin: C.green, triv: C.ink };

  // ---------------------------------------------------------------- strip (left)
  const S = QM.panel(el, { x: 0, y: 0, w: 820, h: 540, m: { l: 30, r: 26, t: 150, b: 64 } });
  const zx = d3.scaleLinear([-1, cfg.zmax], [0, S.iw]);
  const sy = d3.scaleLinear([-0.06, 2.1], [S.ih, 0]);
  const yMu = 1.35, wfh = 0.9;
  // device cut (paper Fig. 1a, d)
  const cut = S.g.append('g').attr('transform', 'translate(0,-136)');
  const ySM = 44, hSM = 40, hSC = 26;
  cut.append('rect').attr('x', zx(-1)).attr('y', ySM).attr('width', zx(-0.75) - zx(-1)).attr('height', hSM).attr('fill', cProbe);
  cut.append('rect').attr('x', zx(-0.75)).attr('y', ySM).attr('width', zx(cfg.zmax) - zx(-0.75)).attr('height', hSM).attr('fill', cSemi);
  cut.append('rect').attr('x', zx(0)).attr('y', ySM - hSC).attr('width', zx(cfg.zmax) - zx(0)).attr('height', hSC).attr('fill', cSuper);
  if (full) cut.append('rect').attr('x', zx(0)).attr('y', ySM + hSM).attr('width', zx(cfg.zmax) - zx(0)).attr('height', hSC).attr('fill', cSuper);
  const lab = (x, y, t, cls = 'text') => S.label(x, y, t, { math: false, cls, ax: 0 });
  lab(zx(-0.98), -136 + ySM - 16, 'probe').style.color = C.ink_2;
  lab(zx(0.12), -136 + ySM - hSC / 2, 'SC').style.color = C.ink_2;
  lab(zx(0.12), -136 + ySM + hSM / 2, 'SM').style.color = C.ink_2;
  const ax0 = zx(0.36 * cfg.zmax), ax1 = zx(0.62 * cfg.zmax), ay = -136 + ySM + hSM / 2;
  cut.append('line').attr('x1', ax0).attr('x2', ax1 - 14).attr('y1', ySM + hSM / 2).attr('y2', ySM + hSM / 2)
    .attr('stroke', '#E00000').attr('stroke-width', 4);
  cut.append('path').attr('d', `M${ax1},${ySM + hSM / 2} l-16,-9 v18 z`).attr('fill', '#E00000');
  S.label(ax1 + 8, ay, full ? '\\Phi' : 'B', { ax: 0 }).style.color = '#E00000';

  // local phases
  const gReg = S.g.append('g');
  const regLabels = [];
  // band bottom e φ_g(z) and μ
  const gEc = S.g.append('path').attr('fill', 'none').attr('stroke', C.ink).attr('stroke-width', 3);
  S.g.append('line').attr('x1', 0).attr('x2', S.iw).attr('y1', sy(yMu)).attr('y2', sy(yMu))
    .attr('stroke', C.muted).attr('stroke-dasharray', '7 5').attr('stroke-width', 2);
  S.label(S.iw - 6, sy(yMu) + 4, '\\mu', { ax: 1, ay: 0 }).style.color = C.muted;
  S.label(zx(-0.5), sy(0.25), 'Ins.', { math: false, cls: 'text' }).style.transform = 'translate(-50%,-50%) rotate(-90deg)';
  // χ bar
  const yChi = 1.78;
  S.g.append('path').attr('d', `M${zx(0)},${sy(yChi) - 7} v14 M${zx(0)},${sy(yChi)} H${zx(1)} M${zx(1)},${sy(yChi) - 7} v14`)
    .attr('stroke', C.ink).attr('stroke-width', 2.5).attr('fill', 'none');
  S.label(zx(1) + 10, sy(yChi), '\\chi', { ax: 0, cls: 'big' });
  // wavefunctions
  const gWf = S.g.append('g').attr('class', 'qm-fade').style('opacity', 0);
  const wfL = gWf.append('path').attr('fill', 'none').attr('stroke', C.navy).attr('stroke-width', 3.2);
  const wfR = gWf.append('path').attr('fill', 'none').attr('stroke', C.orange).attr('stroke-width', 3.2);
  const labL = S.label(0, 0, '|\\Psi_\\mathrm{L}|^2', { ax: 0, cls: 'big', color: C.navy });
  const labR = S.label(0, 0, '|\\Psi_\\mathrm{R}|^2', { ax: 0, cls: 'big', color: C.orange });
  labL.classList.add('qm-fade'); labR.classList.add('qm-fade');
  const yLabL = 1.1;
  const zClearL = full ? 0 : QM.zClear(QMD.muz.z, cfg.Ec(), (yLabL - 0.3) / yMu);
  // axis: 0, 2χ, 4χ, ...
  const zt = d3.range(0, cfg.zmax + 0.01, 2);
  QM.axis(S, 'bottom', zx, { ticks: zt, fmt: (v) => (v === 0 ? '0' : '') });
  zt.slice(1).forEach((v) => S.label(zx(v), S.ih + 22, `${v}\\chi`, { ay: 0, cls: 'small' }));
  S.label(zx(zt[zt.length - 1] - 1), S.ih + 22, 'z', { ay: 0 });
  S.g.append('line').attr('x1', 0).attr('x2', S.iw).attr('y1', S.ih).attr('y2', S.ih).attr('stroke', C.ink).attr('stroke-width', 1.3);
  // hover cursor
  const cursor = S.g.append('line').attr('y1', 0).attr('y2', S.ih).attr('stroke', C.ink).attr('stroke-width', 1.2)
    .attr('stroke-dasharray', '3 3').style('opacity', 0);
  const hover = S.g.append('rect').attr('width', S.iw).attr('height', S.ih).attr('fill', 'transparent')
    .style('cursor', 'crosshair');

  // ---------------------------------------------------------------- phase diagram (right)
  const D = QM.panel(el, { x: 860, y: 0, w: 580, h: 540, m: { l: 92, r: 18, t: 64, b: 78 } });
  const X = d3.scaleLinear(cfg.xdom, [0, D.iw]);
  const Yd = d3.scaleLinear(cfg.ydom, [D.ih, 0]);
  const yy = (m) => Yd(cfg.Y(m));
  D.g.append('rect').attr('width', D.iw).attr('height', D.ih).attr('fill', C.triv);
  // topological region: contour of a fine mask on the display grid
  {
    const nx = cfg.xs.length, ny = 360;
    const vals = new Float64Array(nx * ny);
    const yg = d3.range(ny).map((j) => cfg.ydom[0] + ((cfg.ydom[1] - cfg.ydom[0]) * j) / (ny - 1));
    // invert the display axis numerically: display value → μ
    const muOf = (yv) => { let lo = -2, hi = 3; for (let i = 0; i < 50; i++) { const mid = (lo + hi) / 2; if (cfg.Y(mid) < yv) lo = mid; else hi = mid; } return (lo + hi) / 2; };
    const mus = yg.map(muOf);
    for (let i = 0; i < nx; i++) {
      const iv = cfg.iv[i];
      for (let j = 0; j < ny; j++) {
        const m = mus[j];
        let t = 0;
        for (const [a, b] of iv) if (m >= a && m <= b) { t = 1; break; }
        vals[i + nx * j] = t;
      }
    }
    QM.blur(vals, nx, ny, full ? 9 : 6, full ? 2 : 3);      // as make_figs.jl gblur
    const cont = d3.contours().size([nx, ny]).thresholds([0.5])(vals);
    const gx = d3.scaleLinear([0, nx - 1], [X(cfg.xs[0]), X(cfg.xs[nx - 1])]);
    const gy = d3.scaleLinear([0, ny - 1], [Yd(cfg.ydom[0]), Yd(cfg.ydom[1])]);
    const proj = d3.geoTransform({ point(px, py) { this.stream.point(gx(px - 0.5), gy(py - 0.5)); } });
    const clipId = 'pdclip' + Math.random().toString(36).slice(2);
    D.svg.append('defs').append('clipPath').attr('id', clipId).append('rect').attr('width', D.iw).attr('height', D.ih);
    D.g.append('path').attr('clip-path', `url(#${clipId})`).attr('d', d3.geoPath(proj)(cont[0]))
      .attr('fill', C.topo_tint);
  }
  D.g.append('rect').attr('y', Yd(0)).attr('width', D.iw).attr('height', D.ih - Yd(0)).attr('fill', C.ins);
  D.g.append('line').attr('x1', 0).attr('x2', D.iw).attr('y1', yy(1)).attr('y2', yy(1))
    .attr('stroke', C.muted).attr('stroke-dasharray', '6 5').attr('stroke-width', 1.6);
  D.g.append('line').attr('x1', X(cfg.crit)).attr('x2', X(cfg.crit)).attr('y1', 0).attr('y2', D.ih)
    .attr('stroke', C.crit).attr('stroke-dasharray', '7 5').attr('stroke-width', 2.2);
  const xticks = full ? [0.5, 1, 1.5] : [0, 1, 2];
  QM.axis(D, 'bottom', X, { ticks: xticks });
  D.label(X(cfg.crit) + (full ? -7 : 7), 16, cfg.critTex, { ax: full ? 1 : 0, cls: 'small' }).style.color = C.crit;
  const yt = full ? [0, cfg.Y(P['μts']), 1] : [0, 1];
  QM.axis(D, 'left', Yd, { ticks: full ? [0, cfg.Y(P['μts']), 1] : [0, 1], fmt: () => '' });
  D.label(-12, Yd(0), '0', { ax: 1, math: false, cls: 'text' });
  D.label(-12, yy(1), '\\mu_\\mathrm{bulk}', { ax: 1, cls: 'small' });
  if (full) D.label(-12, Yd(yt[1]), '\\mu^\\mathrm{ts}', { ax: 1, cls: 'small' }).style.color = C.green;
  QM.frame(D);
  D.label(D.iw / 2, D.ih + 56, cfg.xTex, {});
  D.label(-66, D.ih / 2, '\\mu', {});
  // legend
  const leg = [['ins', 'Insulating'], ['triv', 'Trivial'], ['topo', 'Topological']];
  if (full) leg.splice(2, 0, ['skin', 'Trivial skin']);
  let lx = 0;
  leg.forEach(([k, t]) => {
    D.g.append('rect').attr('x', lx).attr('y', -46).attr('width', 18).attr('height', 18).attr('fill', fill[k])
      .attr('stroke', C.ink).attr('stroke-width', 1);
    const l = D.label(lx + 26, -37, t, { math: false, cls: 'text', ax: 0 });
    if (k === 'skin') { l.style.color = C.green; l.style.fontWeight = 700; }
    lx += 26 + t.length * 9.6 + 14;
  });
  if (full) {
    const sl = D.label(X(1.22), yy(0.4), 'Trivial<br>skin', { math: false, cls: 'text' });
    Object.assign(sl.style, { color: C.green, fontWeight: 700, fontSize: '26px', textAlign: 'center', lineHeight: 1.1 });
    sl.classList.add('qm-fade'); sl.style.opacity = 0;
    cfg.skinLabel = sl;
  } else {
    const ml = D.label(X(0.05), yy(1.05), 'μ(z) along the wire', { math: false, cls: 'text', ax: 0, ay: 1 });
    ml.style.color = C.muted; ml.classList.add('qm-fade'); ml.style.opacity = 0;
    cfg.muLabel = ml;
  }
  // path
  const gPath = D.g.append('g');
  const pLab = D.label(0, (Yd(0) + D.ih) / 2, '', { ax: 0, cls: 'small' });
  const chiLabs = ['\\chi', '3\\chi'].map((t) => {
    const l = D.label(0, 0, t, { ax: 1, cls: 'small' });
    l.style.opacity = 0;
    return l;
  });
  const hoverDot = D.g.append('circle').attr('r', 7).attr('fill', '#fff').attr('stroke', C.ink)
    .attr('stroke-width', 2.5).style('opacity', 0);

  // ---------------------------------------------------------------- drawing
  let state = { x: null, wf: null };
  const zs = d3.range(0, cfg.zmax + 1e-9, cfg.zmax / 900);

  function drawStrip(x, zr = Infinity) {
    gReg.selectAll('*').remove();
    regLabels.forEach((l) => l.remove()); regLabels.length = 0;
    gReg.append('rect').attr('x', zx(-1)).attr('width', zx(0) - zx(-1)).attr('height', S.ih).attr('fill', C.ins);
    const zend = Math.max(0, Math.min(zr, cfg.zmax));
    if (x === null || zend < cfg.zmax) {
      gReg.append('rect').attr('x', zx(zend)).attr('width', zx(cfg.zmax) - zx(zend)).attr('height', S.ih).attr('fill', '#fff');
    }
    if (x === null) {
      const l = S.label((zx(0) + zx(cfg.zmax)) / 2, sy(1.95), 'Hybrid wire', { math: false, cls: 'text' });
      regLabels.push(l);
    } else if (zend > 0) {
      const muz = cfg.muz(x);
      const zz = zs.filter((z) => z <= zend);
      const ph = zz.map((z) => phase(x, QM.interp(zpos, muz, z)));
      let s0 = 0;
      for (let i = 1; i <= zz.length; i++) {
        if (i === zz.length || ph[i] !== ph[s0]) {
          const za = zz[s0], zb = i === zz.length ? zend : zz[i];
          const k = ph[s0];
          gReg.append('rect').attr('x', zx(za)).attr('width', zx(zb) - zx(za) + 0.6).attr('height', S.ih).attr('fill', fill[k]);
          if (zx(zb) - zx(za) > 70) {
            const t = { topo: 'Topological', triv: 'Trivial', skin: 'Trivial skin', ins: '' }[k];
            const l = S.label((zx(za) + zx(zb)) / 2, sy(1.95), t, { math: false, cls: 'text' });
            if (k === 'skin') { l.style.color = C.green; l.style.fontWeight = 700; }
            regLabels.push(l);
          }
          if (k === 'skin' && i < zz.length) gReg.append('line').attr('x1', zx(zb)).attr('x2', zx(zb)).attr('y2', S.ih).attr('stroke', C.green).attr('stroke-width', 1.4);
          s0 = i;
        }
      }
    }
    const Ec = cfg.Ec(x === null ? cfg.presets[1] : x);
    const zall = QMD.muz.z;
    const pts = zall.map((z, i) => [z, Ec[i]]).filter(([z]) => z <= cfg.zmax);
    gEc.attr('d', d3.line().x((d) => zx(d[0])).y((d) => sy(Math.min(yMu * d[1], 2.08)))(pts));
  }

  const yOf = (m) => (m <= 0 ? Yd(Math.max(m, cfg.ydom[0])) : yy(m));
  function drawPath(x, muTip = Infinity) {
    gPath.selectAll('*').remove();
    if (x === null) { pLab.style.opacity = 0; chiLabs.forEach((l) => { l.style.opacity = 0; }); return; }
    const iv = ivAt(x);
    const top = Math.min(muTip, 1);
    // phase boundaries in μ along the path
    const cuts = [cfg.ydom[0], 0];
    for (const [a, b] of iv) { if (a > 0 && a < 1) cuts.push(a); if (b > 0 && b < 1) cuts.push(b); }
    cuts.push(1);
    cuts.sort((a, b) => a - b);
    for (let i = 0; i < cuts.length - 1; i++) {
      const m0 = cuts[i];
      if (m0 >= top) break;
      const m1 = Math.min(cuts[i + 1], top);
      const k = phase(x, (m0 + m1) / 2);
      gPath.append('line').attr('x1', X(x)).attr('x2', X(x)).attr('y1', yOf(m0)).attr('y2', yOf(m1))
        .attr('stroke', ink[k]).attr('stroke-width', k === 'skin' ? 9 : 5.5);
    }
    if (top >= 0.999) {
      const kTop = phase(x, 0.999);
      gPath.append('path').attr('d', `M${X(x)},${yy(1) - 13} l-10,17 h20 z`).attr('fill', ink[kTop])
        .attr('stroke', '#fff').attr('stroke-width', 1.5);
    } else if (top > cfg.ydom[0]) {
      gPath.append('circle').attr('cx', X(x)).attr('cy', yOf(top)).attr('r', 8).attr('fill', ink[phase(x, top)])
        .attr('stroke', '#fff').attr('stroke-width', 2.5);
    }
    // z = χ, 2χ, 3χ marks, once the path has reached them
    const muz = cfg.muz(x);
    [1, 2, 3].forEach((n) => {
      const m = QM.interp(zpos, muz, n);
      if (m > top) return;
      gPath.append('line').attr('x1', X(x) - 9).attr('x2', X(x) + 9).attr('y1', yy(m)).attr('y2', yy(m))
        .attr('stroke', C.ink).attr('stroke-width', 2.2);
    });
    chiLabs.forEach((l, i) => {
      const n = [1, 3][i];
      const m = QM.interp(zpos, muz, n);
      l.style.left = D.m.l + X(x) - 14 + 'px';
      l.style.top = D.m.t + yy(m) + 'px';
      l.style.opacity = m <= top ? 1 : 0;
    });
    pLab.style.left = D.m.l + X(x) + 12 + 'px';
    pLab.style.opacity = 1;
  }

  function drawWf(which) {
    if (!which) { gWf.style('opacity', 0); labL.style.opacity = 0; labR.style.opacity = 0; return; }
    const d = cfg.wf[which];
    const lineF = d3.line().x((v, i) => zx(d.z[i])).y((v) => sy(wfh * v));
    const keep = (arr) => arr.map((v, i) => (d.z[i] <= cfg.zmax ? v : null)).filter((v) => v !== null);
    wfL.attr('d', lineF(keep(d.L)));
    wfR.attr('d', which === 'QMajo' ? lineF(keep(d.R)) : null);
    gWf.style('opacity', 1);
    const iL = d.L.indexOf(Math.max(...d.L));
    const iR = d.R.indexOf(Math.max(...d.R));
    // partial shell: Ψ_L peaks right under the band bottom, so its label goes above the
    // curve, from the first z where the curve has dropped clear of it
    const [placeL, yL] = full ? [zx(d.z[iL]) - 132, 0.97] : [Math.max(zx(zClearL), zx(d.z[iL]) + 26), yLabL];
    labL.style.left = S.m.l + placeL + 'px'; labL.style.top = S.m.t + sy(yL) + 'px';
    labL.style.opacity = 1;
    if (which === 'QMajo') {
      // partial shell: right of the peak, from where the falling flank has dropped clear of it
      const yR = 0.82;
      let jR = iR;
      while (!full && jR < d.R.length - 1 && wfh * d.R[jR] > yR - 0.22) jR++;
      const placeR = full ? zx(d.z[iR]) - 146 : zx(d.z[jR]) + 10;
      labR.style.left = S.m.l + placeR + 'px'; labR.style.top = S.m.t + sy(yR) + 'px';
      labR.style.opacity = 1;
    } else labR.style.opacity = 0;
  }

  function render(x, wf) {
    drawStrip(x); drawPath(x); drawWf(wf);
    if (cfg.skinLabel) cfg.skinLabel.style.opacity = x === null ? 0 : 1;
    if (cfg.muLabel) cfg.muLabel.style.opacity = x === null ? 0 : 1;
    gauge.style('opacity', 0); gaugeLab.style.opacity = 0;
    state = { x, wf };
  }

  // Gauge: the local chemical potential μ(z) is the gap between μ and the band bottom
  const gauge = S.g.append('g').style('opacity', 0).style('pointer-events', 'none');
  const gaugeLine = gauge.append('line').attr('stroke-width', 5).attr('stroke-linecap', 'round');
  const gaugeEnds = gauge.append('path').attr('stroke-width', 2.5).attr('fill', 'none');
  const gaugeLab = S.label(0, 0, '\\mu(z)', { ax: 0 });
  gaugeLab.style.opacity = 0;
  function placeGauge(x, z, m) {
    const ya = sy(yMu), yb = sy(yMu * (1 - m));
    const col = ink[phase(x, m)];
    gaugeLine.attr('x1', zx(z)).attr('x2', zx(z)).attr('y1', ya).attr('y2', yb).attr('stroke', col);
    gaugeEnds.attr('d', `M${zx(z) - 9},${ya} h18 M${zx(z) - 9},${yb} h18`).attr('stroke', col);
    gauge.style('opacity', 1);
    Object.assign(gaugeLab.style, { left: S.m.l + zx(z) + 12 + 'px', top: S.m.t + (ya + yb) / 2 + 'px', opacity: 1, color: col });
  }
  function walk(x, done) {
    const zall = QMD.muz.z, Ec = cfg.Ec(x);
    let iPk = 0;                                   // start on top of the barrier, where μ(z) is lowest
    for (let i = 0; i < zall.length && zall[i] < 0; i++) if (Ec[i] > Ec[iPk]) iPk = i;
    const z0 = zall[iPk];
    const muAt = (z) => 1 - QM.interp(zall, Ec, z);
    drawWf(null);
    if (cfg.skinLabel) cfg.skinLabel.style.opacity = 0;
    if (cfg.muLabel) cfg.muLabel.style.opacity = 1;
    state = { x, wf: null };
    return QM.tween(cfg.walkMs, (t) => {
      const z = QM.lerp(z0, cfg.zmax, t);
      const m = muAt(z);
      drawStrip(x, z); drawPath(x, m); placeGauge(x, z, m);
    }, () => { render(x, 'Majo'); if (done) done(); }, (t) => t);
  }

  // hover: z on the wire ↔ μ(z) on the path
  hover.on('pointermove', (ev) => {
    if (state.x === null) return;
    const [px] = d3.pointer(ev);
    const z = zx.invert(px);
    if (z < 0) { cursor.style('opacity', 0); hoverDot.style('opacity', 0); return; }
    const m = QM.interp(zpos, cfg.muz(state.x), z);
    cursor.attr('x1', px).attr('x2', px).style('opacity', 1);
    hoverDot.attr('cx', X(state.x)).attr('cy', yy(Math.min(m, 1))).style('opacity', 1);
  }).on('pointerleave', () => { cursor.style('opacity', 0); hoverDot.style('opacity', 0); });

  let stop = () => {};
  return {
    go(step, animate) {
      stop();
      const k = Math.min(step, 2);
      const target = cfg.presets[k];
      const wf = k === 1 ? 'Majo' : k === 2 ? 'QMajo' : null;
      QM.tex(pLab, k === 0 ? '' : cfg.pTex[k - 1]);
      if (animate && k === 1 && state.x === null) { stop = walk(target); return; }
      if (!animate || state.x === null || target === null) { render(target, wf); return; }
      const from = state.x;
      render(from, null);
      stop = QM.tween(900, (t) => render(QM.lerp(from, target, t), null), () => render(target, wf));
    },
    leave() { stop(); },
  };
});
