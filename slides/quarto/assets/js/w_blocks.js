// Symmetry structure of the full-shell Hamiltonian. [H, J_z] = 0 splits H into m_J sectors,
// drawn as a row H = ⋯ ⊕ H_{−2} ⊕ … ⊕ H_{+2} ⊕ ⋯. Particle–hole symmetry maps m_J → −m_J
// (arcs), so a sector m_J ≠ 0 has no 𝒫 of its own (class A, by 𝒫 alone); only the
// self-conjugate m_J = 0 sector keeps it (class D).
// Steps: 0 sectors, 1 𝒫 pairs them, 2 symmetry classes.
QM.register('blocks', (el, opts) => {
  const C = QM.c;
  const W = +opts.w || 680, H = +opts.h || 420;
  const p = QM.panel(el, { x: 0, y: 0, w: W, h: H, m: { l: 0, r: 0, t: 0, b: 0 } });
  const ms = [-2, -1, 0, 1, 2];
  const bw = 92, gap = 34, y0 = 170;
  const x0 = (W - (ms.length * bw + (ms.length - 1) * gap)) / 2;
  const cx = (i) => x0 + i * (bw + gap) + bw / 2;
  const blocks = ms.map((m, i) => {
    const r = p.g.append('rect').attr('x', cx(i) - bw / 2).attr('y', y0).attr('width', bw).attr('height', bw)
      .attr('rx', 12).attr('stroke-width', 2.2).attr('fill', '#fff').attr('stroke', C.ink_2)
      .style('transition', 'fill 0.5s, stroke 0.5s');
    p.label(cx(i), y0 + bw / 2, `H_{${m > 0 ? '+' : ''}${m}}`, { cls: 'big' });
    if (i < ms.length - 1) p.label(cx(i) + bw / 2 + gap / 2, y0 + bw / 2, '\\oplus', {}).style.color = C.muted;
    return { m, r, i };
  });
  p.label(x0 - 24, y0 + bw / 2, '\\cdots\\oplus', { ax: 1 }).style.color = C.muted;
  p.label(x0 + ms.length * (bw + gap) - gap + 24, y0 + bw / 2, '\\oplus\\cdots', { ax: 0 }).style.color = C.muted;

  // 𝒫 arcs above the row
  const arcs = p.g.append('g').attr('class', 'qm-fade').style('opacity', 0);
  const arc = (i, j, hgt, color, dash) => arcs.append('path')
    .attr('d', `M${cx(i)},${y0 - 6} C${cx(i)},${y0 - hgt} ${cx(j)},${y0 - hgt} ${cx(j)},${y0 - 6}`)
    .attr('fill', 'none').attr('stroke', color).attr('stroke-width', 2.4).attr('stroke-dasharray', dash);
  arc(0, 4, 150, C.navy, '7 5');
  arc(1, 3, 95, C.navy, '7 5');
  arcs.append('path').attr('d', `M${cx(2) - 16},${y0 - 6} C${cx(2) - 34},${y0 - 64} ${cx(2) + 34},${y0 - 64} ${cx(2) + 16},${y0 - 6}`)
    .attr('fill', 'none').attr('stroke', C.red).attr('stroke-width', 2.6);
  [0, 1, 3, 4].forEach((i) => arcs.append('path').attr('d', `M${cx(i)},${y0 - 4} l-6,-11 h12 z`).attr('fill', C.navy));
  arcs.append('path').attr('d', `M${cx(2) + 16},${y0 - 4} l-1,-12 l9,6 z`).attr('fill', C.red);
  const pl = p.label(W / 2, y0 - 168, '\\mathcal{P}:\\ m_J \\to -m_J', { color: C.navy });
  pl.classList.add('qm-fade'); pl.style.opacity = 0;

  // classes below the row
  const tags = [];
  ms.forEach((m, i) => {
    const t = p.label(cx(i), y0 + bw + 30, m === 0 ? 'D' : 'A', { math: false, cls: 'tag' });
    t.style.background = m === 0 ? C.red : C.ink_2;
    t.classList.add('qm-fade'); t.style.opacity = 0;
    tags.push(t);
  });
  const sub = [
    p.label((cx(0) + cx(1)) / 2, y0 + bw + 80, 'trivial<br>(CdGM analogs)', { math: false, cls: 'text' }),
    p.label(cx(2), y0 + bw + 80, 'Majoranas', { math: false, cls: 'text' }),
    p.label((cx(3) + cx(4)) / 2, y0 + bw + 80, 'trivial<br>(CdGM analogs)', { math: false, cls: 'text' }),
  ];
  sub.forEach((l, k) => {
    Object.assign(l.style, { textAlign: 'center', lineHeight: 1.2, color: k === 1 ? C.red : C.ink_2, opacity: 0 });
    if (k === 1) l.style.fontWeight = 700;
    l.classList.add('qm-fade');
  });

  return {
    go(step) {
      arcs.style('opacity', step >= 1 ? 1 : 0);
      pl.style.opacity = step >= 1 ? 1 : 0;
      [...tags, ...sub].forEach((t) => { t.style.opacity = step >= 2 ? 1 : 0; });
      blocks.forEach(({ m, r }) => {
        if (step >= 2) r.attr('fill', m === 0 ? C.red_tint : C.surface).attr('stroke', m === 0 ? C.red : C.faint);
        else r.attr('fill', '#fff').attr('stroke', C.ink_2);
      });
    },
  };
});
