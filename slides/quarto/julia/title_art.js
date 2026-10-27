// Title-slide illustration (assets/img/title_art.svg): a full-shell nanowire in perspective on a
// dark field, in the colours of the deck's schematics (blue superconducting shell, yellow
// semiconducting core), threaded by the axial flux, the pairing phase winding once around the
// shell (n = 1) and a glowing pair hidden deep inside, seen through a window cut in the shell.
// Decorative, not data.
// Run: node slides/quarto/julia/title_art.js
const fs = require('fs');
const path = require('path');

const W = 600, H = 900;
const C0 = [210, 700], R0 = 165;          // near end face (screen px)
const C1 = [540, -60], R1 = 34;           // far end, off the top of the panel (not its side)
const f = R1 / R0;
const V = [(C1[0] - f * C0[0]) / (1 - f), (C1[1] - f * C0[1]) / (1 - f)];   // vanishing point
const s = (u) => 1 / (1 + u * (1 / f - 1));                                  // perspective scale
const C = (u) => [V[0] + (C0[0] - V[0]) * s(u), V[1] + (C0[1] - V[1]) * s(u)];
const core = 0.74;                                                           // core / shell radius
const hex = (c, r) => [...Array(6)].map((_, k) => [c[0] + r * Math.cos((k * Math.PI) / 3), c[1] + r * Math.sin((k * Math.PI) / 3)]);
const pts = (a) => a.map((p) => p.map((x) => x.toFixed(1)).join(',')).join(' ');
const ax = [C(1)[0] - C0[0], C(1)[1] - C0[1]];

// seeded RNG so the star field is reproducible
let seed = 7;
const rnd = () => ((seed = (seed * 16807) % 2147483647) / 2147483647);

// side faces of a hexagonal prism of radius r (at u = 0) between depths u0 and u1, split by
// whether they face the viewer; n: outward normal of the face (screen), for the shading
function faces(r, u0 = 0, u1 = 1) {
  const a = hex(C(u0), r * s(u0)), b = hex(C(u1), r * s(u1)), a0 = hex(C0, r);
  return a.map((p, k) => {
    const q = a[(k + 1) % 6], m = [(a0[k][0] + a0[(k + 1) % 6][0]) / 2 - C0[0], (a0[k][1] + a0[(k + 1) % 6][1]) / 2 - C0[1]];
    const nn = Math.hypot(m[0], m[1]);
    return { poly: [p, q, b[(k + 1) % 6], b[k]], front: m[0] * ax[0] + m[1] * ax[1] > 0, n: [m[0] / nn, m[1] / nn] };
  });
}
const mix = (a, b, t) => '#' + [0, 2, 4].map((i) => Math.round(parseInt(a.slice(1 + i, 3 + i), 16) * (1 - t) + parseInt(b.slice(1 + i, 3 + i), 16) * t).toString(16).padStart(2, '0')).join('');
const light = [-0.6, -0.8];                                                  // from the upper left
const lit = (n, sign = 1) => Math.max(0, sign * (n[0] * light[0] + n[1] * light[1]));
const face = (q, dark, bright, sign = 1, stroke = bright) =>
  `<polygon points="${pts(q.poly)}" fill="${mix(dark, bright, 0.2 + 0.8 * lit(q.n, sign))}" stroke="${stroke}" stroke-opacity="0.55" stroke-width="1" stroke-linejoin="round"/>`;

const out = [];
out.push(`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">`);
out.push(`<defs>
  <radialGradient id="haze" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFF1B0" stop-opacity="0.12"/><stop offset="1" stop-color="#FFF1B0" stop-opacity="0"/></radialGradient>
  <linearGradient id="shellF" x1="0" y1="1" x2="1" y2="0"><stop offset="0" stop-color="#B8C7F9" stop-opacity="0.16"/><stop offset="1" stop-color="#7E97EA" stop-opacity="0.06"/></linearGradient>
  <linearGradient id="ring" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#C9D5FB"/><stop offset="1" stop-color="#7E97EA"/></linearGradient>
  <radialGradient id="coreFace" cx="0.5" cy="0.5" r="0.55"><stop offset="0" stop-color="#E3CD52"/><stop offset="0.7" stop-color="#F1E6A6"/><stop offset="1" stop-color="#F7F0C0"/></radialGradient>
  <linearGradient id="fadeR" x1="0" y1="0" x2="${W}" y2="0" gradientUnits="userSpaceOnUse"><stop offset="0.7" stop-color="#fff"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
  <mask id="edge" maskUnits="userSpaceOnUse" x="0" y="0" width="${W}" height="${H}"><rect width="${W}" height="${H}" fill="url(#fadeR)"/></mask>
  <filter id="blur8" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="8"/></filter>
  <filter id="blur22" x="-80%" y="-80%" width="260%" height="260%"><feGaussianBlur stdDeviation="22"/></filter>
  <filter id="soft" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="1.2"/></filter>
</defs>`);
// no background: the slide's hero panel provides it (same gradient), and extends it past the slide

// star field
for (let i = 0; i < 140; i++) {
  const x = rnd() * W, y = rnd() * H, r = 0.4 + rnd() * 1.3, o = 0.08 + rnd() * 0.35;
  out.push(`<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${r.toFixed(2)}" fill="#DDE5FF" opacity="${o.toFixed(2)}"/>`);
}

// axial flux: field lines converging to the vanishing point; with the haze, faded out towards the
// right edge, where the panel continues past the slide without them
out.push('<g mask="url(#edge)">');
for (let i = 0; i < 17; i++) {
  const a = (-0.95 + (1.9 * i) / 16) * Math.PI / 2.2 + Math.atan2(C0[1] - V[1], C0[0] - V[0]);
  const L = 1300 + 200 * rnd();
  const p = [V[0] + L * Math.cos(a), V[1] + L * Math.sin(a)];
  out.push(`<line x1="${p[0].toFixed(1)}" y1="${p[1].toFixed(1)}" x2="${V[0].toFixed(1)}" y2="${V[1].toFixed(1)}" stroke="#AFC2FF" stroke-width="1" opacity="${(0.05 + 0.07 * rnd()).toFixed(2)}"/>`);
}

// haze behind the hidden pair
const uA = 0.11, uB = 0.24;
const mid = C((uA + uB) / 2), hr = 260 * s((uA + uB) / 2);
out.push(`<ellipse cx="${mid[0].toFixed(1)}" cy="${mid[1].toFixed(1)}" rx="${(hr * 1.9).toFixed(1)}" ry="${(hr * 1.9).toFixed(1)}" fill="url(#haze)"/>`);
out.push('</g>');

// a window cut in the front of the shell between uW0 and uW1 shows the core; painted far to near
const uW0 = 0.025, uW1 = 0.33;
const SH = ['#5F78CF', '#DCE4FD'], IN = ['#33467F', '#7E97EA'], CO = ['#CDB54E', '#FBF5D2'];
// inner wall of the shell (its back faces, seen from inside)
faces(R0).filter((q) => !q.front).forEach((q) => out.push(face(q, IN[0], IN[1], -1, '#8EA4EE')));
// shell beyond the window
faces(R0, uW1, 1).filter((q) => q.front).forEach((q) => out.push(face(q, SH[0], SH[1])));
// the cut rim at the far edge of the window: the thickness of the shell
const rim = (u) => `M${pts(hex(C(u), R0 * s(u))).replace(/ /g, ' L')} Z M${pts(hex(C(u), R0 * core * s(u))).replace(/ /g, ' L')} Z`;
out.push(`<path d="${rim(uW1)}" fill="#E8EEFE" fill-rule="evenodd" stroke="#C9D5FB" stroke-width="1"/>`);
// core up to the rim
faces(R0 * core, 0, uW1).filter((q) => q.front).forEach((q) => out.push(face(q, CO[0], CO[1])));

// the pair: glows at the two edges of the hidden topological segment, a faint thread between
const dir = Math.atan2(V[1] - C0[1], V[0] - C0[0]) * 180 / Math.PI;
const glow = (u, k) => {
  const c = C(u), r = R0 * core * s(u);
  return `<g transform="translate(${c[0].toFixed(1)},${c[1].toFixed(1)}) rotate(${dir.toFixed(1)})">
    <ellipse rx="${(r * 1.4 * k).toFixed(1)}" ry="${(r * 0.8).toFixed(1)}" fill="#E07B24" opacity="0.5" filter="url(#blur22)"/>
    <ellipse rx="${(r * 0.8 * k).toFixed(1)}" ry="${(r * 0.46).toFixed(1)}" fill="#F2A33A" opacity="0.85" filter="url(#blur8)"/>
    <ellipse rx="${(r * 0.36 * k).toFixed(1)}" ry="${(r * 0.2).toFixed(1)}" fill="#FFFBE6" opacity="0.95" filter="url(#blur8)"/>
  </g>`;
};
const n = 40;
const thread = [...Array(n + 1)].map((_, i) => C(uA + ((uB - uA) * i) / n));
out.push(`<polyline points="${pts(thread)}" fill="none" stroke="#F2A33A" stroke-width="${(9 * s(0.3)).toFixed(1)}" stroke-linecap="round" opacity="0.5" filter="url(#blur8)"/>`);
out.push(glow(uA, 1.15), glow(uB, 1.15));

// the collar of shell before the window
faces(R0, 0, uW0).filter((q) => q.front).forEach((q) => out.push(face(q, SH[0], SH[1])));

// near end face: shell ring and core
out.push(`<polygon points="${pts(hex(C0, R0))}" fill="url(#ring)" stroke="#D6DFFC" stroke-width="1.6" stroke-linejoin="round"/>`);
out.push(`<polygon points="${pts(hex(C0, R0 * core))}" fill="url(#coreFace)" stroke="#8C7A2A" stroke-opacity="0.6" stroke-width="1.4" stroke-linejoin="round"/>`);

// pairing phase on the shell: winds once going around (n = 1), as on the Little–Parks slide;
// arrows on the midline of the ring (its vertices and edge midpoints)
const Rm = R0 * (1 + core) / 2;
for (let k = 0; k < 12; k++) {
  const phi = (2 * Math.PI * k) / 12, rr = k % 2 ? Rm * Math.cos(Math.PI / 6) : Rm;
  const x = C0[0] + rr * Math.cos(phi), y = C0[1] + rr * Math.sin(phi);
  const th = (phi * 180) / Math.PI + 90;
  out.push(`<g transform="translate(${x.toFixed(1)},${y.toFixed(1)}) rotate(${th.toFixed(1)})"><path d="M-9,0 H4 M10,0 L2,-5 V5 Z" stroke="#0E1838" stroke-width="2.4" fill="#0E1838" stroke-linejoin="round" opacity="0.85"/></g>`);
}
out.push('</svg>');

fs.writeFileSync(path.join(__dirname, '..', 'assets', 'img', 'title_art.svg'), out.join('\n'));
console.log('wrote assets/img/title_art.svg');
