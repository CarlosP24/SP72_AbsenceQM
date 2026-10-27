// Runtime of the interactive figures ("widgets") of the talk.
//
// A widget is a div on a slide:
//   ::: {.qm-widget data-widget="name" style="width:720px;height:480px"}
//   :::
// Its size must be explicit (slides that are not shown have no layout to measure).
// Factories register with QM.register(name, (el, opts) => instance) and may return
//   go(step, animate)  move to a preset state; step = number of visible .qm-step
//                      fragments on the slide (so text fragments can drive figures)
//   enter() / leave()  called when the slide is shown / left
// Data come from assets/data/*.js (window.QMD), written by julia/export_data.jl.
(() => {
  const QM = (window.QM = { reg: {}, all: [] });

  // ---------------------------------------------------------------------------
  // Palette (theme CSS custom properties) and small helpers
  // ---------------------------------------------------------------------------
  const cssVar = (name) =>
    getComputedStyle(document.documentElement).getPropertyValue(name).trim();
  QM.c = {};
  const palette = () => {
    for (const k of ['ink', 'ink-2', 'muted', 'faint', 'line', 'surface', 'red', 'red-tint',
      'topo-tint', 'green', 'green-tint', 'skin-tint', 'navy', 'navy-tint', 'orange',
      'orange-tint', 'ins', 'triv', 'crit']) {
      QM.c[k.replace('-', '_')] = cssVar('--qd-' + k) || '#000';
    }
  };

  // Colour of each case where a slide links them across panels: true MZM, quasi-MZM
  Object.defineProperty(QM, 'caseColor', { get: () => ({ Majo: QM.c.navy, QMajo: QM.c.red }) });

  QM.clamp = (x, a, b) => Math.max(a, Math.min(b, x));
  QM.lerp = (a, b, t) => a + (b - a) * t;
  QM.ease = (t) => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2);
  // First z ≥ 0 past which the band bottom ys(z) stays below level (to clear labels off it)
  QM.zClear = (zs, ys, level) => {
    for (let i = zs.length - 1; i >= 0; i--) if (zs[i] >= 0 && ys[i] >= level) return zs[i];
    return 0;
  };

  // Linear interpolation of y(x) on a sorted grid
  QM.interp = (xs, ys, x) => {
    const n = xs.length;
    if (x <= xs[0]) return ys[0];
    if (x >= xs[n - 1]) return ys[n - 1];
    let lo = 0, hi = n - 1;
    while (hi - lo > 1) {
      const mid = (lo + hi) >> 1;
      if (xs[mid] <= x) lo = mid; else hi = mid;
    }
    const t = (x - xs[lo]) / (xs[hi] - xs[lo]);
    return ys[lo] + t * (ys[hi] - ys[lo]);
  };

  // Index of the grid point nearest to x
  QM.nearest = (xs, x) => {
    let best = 0;
    for (let i = 1; i < xs.length; i++) if (Math.abs(xs[i] - x) < Math.abs(xs[best] - x)) best = i;
    return best;
  };

  // Separable Gaussian blur of an nx × ny grid in place (σ in cells; edges clamped)
  QM.blur = (v, nx, ny, sx, sy) => {
    const pass = (n, m, s, idx) => {
      if (!(s > 0)) return;
      const r = Math.ceil(3 * s);
      const w = d3.range(-r, r + 1).map((k) => Math.exp(-(k * k) / (2 * s * s)));
      const tot = d3.sum(w);
      const tmp = new Float64Array(n);
      for (let j = 0; j < m; j++) {
        for (let i = 0; i < n; i++) {
          let acc = 0;
          for (let k = -r; k <= r; k++) acc += w[k + r] * v[idx(Math.min(n - 1, Math.max(0, i + k)), j)];
          tmp[i] = acc / tot;
        }
        for (let i = 0; i < n; i++) v[idx(i, j)] = tmp[i];
      }
    };
    pass(nx, ny, sx, (i, j) => i + nx * j);
    pass(ny, nx, sy, (i, j) => j + nx * i);
    return v;
  };

  // 8-bit heat map from the exporter: {nx, ny, b64} → Uint8Array (x fastest)
  QM.u8 = (q) => {
    if (!q._u8) {
      const s = atob(q.b64);
      const a = new Uint8Array(s.length);
      for (let i = 0; i < s.length; i++) a[i] = s.charCodeAt(i);
      q._u8 = a;
    }
    return q._u8;
  };

  // ---------------------------------------------------------------------------
  // Math labels (KaTeX), positioned over an SVG
  // ---------------------------------------------------------------------------
  QM.tex = (el, tex, display = false) => {
    if (window.katex) katex.render(tex, el, { throwOnError: false, displayMode: display });
    else el.textContent = tex;
  };

  // ---------------------------------------------------------------------------
  // Figure scaffold: a positioned box holding canvases (heat maps), one SVG and a
  // layer of HTML labels, all in slide pixels.
  // ---------------------------------------------------------------------------
  QM.box = (parent, x, y, w, h) => {
    const d = document.createElement('div');
    d.className = 'qm-box';
    Object.assign(d.style, { left: x + 'px', top: y + 'px', width: w + 'px', height: h + 'px' });
    parent.appendChild(d);
    return d;
  };

  QM.panel = (el, { x = 0, y = 0, w, h, m = { l: 70, r: 20, t: 20, b: 60 } }) => {
    const box = QM.box(el, x, y, w, h);
    const iw = w - m.l - m.r, ih = h - m.t - m.b;
    const svg = d3.select(box).append('svg').attr('width', w).attr('height', h)
      .attr('class', 'qm-svg');
    const g = svg.append('g').attr('transform', `translate(${m.l},${m.t})`);
    const labels = document.createElement('div');
    labels.className = 'qm-labels';
    box.appendChild(labels);
    const p = { box, svg, g, w, h, m, iw, ih, labels };
    // HTML/KaTeX label at plot coordinates (px from the plot origin); anchor in [0..1]²
    p.label = (px, py, tex, { ax = 0.5, ay = 0.5, cls = '', math = true, color } = {}) => {
      const s = document.createElement('div');
      s.className = 'qm-label ' + cls;
      s.style.left = m.l + px + 'px';
      s.style.top = m.t + py + 'px';
      s.style.transform = `translate(${-100 * ax}%, ${-100 * ay}%)`;
      if (color) s.style.color = color;
      if (math) QM.tex(s, tex); else s.innerHTML = tex;
      labels.appendChild(s);
      return s;
    };
    // Canvas under the SVG, clipped to the plot area (for heat maps). It covers the plot
    // area by default; positions set on it later are relative to the plot origin.
    p.canvas = () => {
      if (!p.clip) {
        p.clip = document.createElement('div');
        p.clip.className = 'qm-clip';
        Object.assign(p.clip.style, { left: m.l + 'px', top: m.t + 'px', width: iw + 'px', height: ih + 'px' });
        box.insertBefore(p.clip, box.firstChild);
      }
      const c = document.createElement('canvas');
      c.className = 'qm-canvas';
      Object.assign(c.style, { left: '0px', top: '0px', width: iw + 'px', height: ih + 'px' });
      p.clip.appendChild(c);
      return c;
    };
    return p;
  };

  // Axes in the house style. opts: ticks (values), fmt (value → string), size
  QM.axis = (p, which, scale, { ticks, fmt, tickSize = 6, grid = false, labels = true } = {}) => {
    let a;
    if (which === 'bottom') a = d3.axisBottom(scale);
    else if (which === 'left') a = d3.axisLeft(scale);
    else if (which === 'top') a = d3.axisTop(scale);
    else a = d3.axisRight(scale);
    if (ticks) a.tickValues(ticks);
    a.tickSize(tickSize).tickPadding(7).tickSizeOuter(0);
    a.tickFormat(labels ? (fmt || QM.fmt) : () => '');
    const g = p.g.append('g').attr('class', 'qm-axis qm-axis-' + which);
    if (which === 'bottom') g.attr('transform', `translate(0,${p.ih})`);
    if (which === 'right') g.attr('transform', `translate(${p.iw},0)`);
    g.call(a);
    return g;
  };

  // Plot frame (four spines)
  QM.frame = (p) => p.g.append('rect').attr('class', 'qm-frame')
    .attr('width', p.iw).attr('height', p.ih);

  // Numbers with a true minus sign
  QM.fmt = (v) => {
    const s = (Math.abs(v) < 1e-12 ? 0 : v).toString();
    return s.replace('-', '−');
  };

  // ---------------------------------------------------------------------------
  // Heat maps
  // ---------------------------------------------------------------------------
  QM.lut = (name = 'thermal') => QMD.cmap[name];

  // Draw an 8-bit map into a canvas (y grows upwards in the data)
  QM.heat = (canvas, q, { lut = QM.lut(), alpha = 255, x0 = 0, x1 = q.nx } = {}) => {
    const a = QM.u8(q);
    const nx = x1 - x0, ny = q.ny;
    canvas.width = nx; canvas.height = ny;
    const ctx = canvas.getContext('2d');
    const img = ctx.createImageData(nx, ny);
    for (let j = 0; j < ny; j++) {
      const row = (ny - 1 - j) * nx;
      for (let i = 0; i < nx; i++) {
        const v = a[(i + x0) + q.nx * j];
        const c = lut[v];
        const k = 4 * (row + i);
        img.data[k] = c[0]; img.data[k + 1] = c[1]; img.data[k + 2] = c[2]; img.data[k + 3] = alpha;
      }
    }
    ctx.putImageData(img, 0, 0);
    return canvas;
  };

  // Colour bar (vertical) next to a panel, from a LUT
  QM.colorbar = (p, { x, y = 0, w = 14, h = p.ih, lut = QM.lut(), ticks = ['0', '1'], label = '' }) => {
    const id = 'cb' + Math.random().toString(36).slice(2);
    const defs = p.svg.append('defs');
    const grad = defs.append('linearGradient').attr('id', id)
      .attr('x1', 0).attr('y1', 1).attr('x2', 0).attr('y2', 0);
    for (let i = 0; i <= 16; i++) {
      const c = lut[Math.round((255 * i) / 16)];
      grad.append('stop').attr('offset', i / 16).attr('stop-color', `rgb(${c[0]},${c[1]},${c[2]})`);
    }
    const g = p.g.append('g').attr('transform', `translate(${x},${y})`);
    g.append('rect').attr('width', w).attr('height', h).attr('fill', `url(#${id})`)
      .attr('stroke', QM.c.ink).attr('stroke-width', 1);
    g.append('text').attr('class', 'qm-tick').attr('x', w + 6).attr('y', h).attr('dy', '0.32em').text(ticks[0]);
    g.append('text').attr('class', 'qm-tick').attr('x', w + 6).attr('y', 0).attr('dy', '0.32em').text(ticks[1]);
    if (label) {
      g.append('text').attr('class', 'qm-cblabel')
        .attr('transform', `translate(${w + 28},${h / 2}) rotate(90)`).attr('text-anchor', 'middle').text(label);
    }
    return g;
  };

  // ---------------------------------------------------------------------------
  // Controls
  // ---------------------------------------------------------------------------
  // Slider with a KaTeX label and a live value. Blurs on release so that the arrow
  // keys go back to reveal.js.
  QM.slider = (parent, { x, y, w = 300, min, max, step = 'any', value, tex = '', fmt = (v) => v.toFixed(2),
    oninput }) => {
    const box = QM.box(parent, x, y, w, 40);
    box.classList.add('qm-slider');
    const lab = document.createElement('span');
    lab.className = 'qm-slider-label';
    QM.tex(lab, tex);
    const inp = document.createElement('input');
    Object.assign(inp, { type: 'range', min, max, step, value });
    const val = document.createElement('span');
    val.className = 'qm-slider-value';
    box.append(lab, inp, val);
    const show = () => { val.textContent = fmt(+inp.value); };
    inp.addEventListener('input', () => { show(); oninput(+inp.value); });
    inp.addEventListener('change', () => inp.blur());
    inp.addEventListener('pointerup', () => setTimeout(() => inp.blur(), 0));
    show();
    return {
      el: box,
      set(v) { inp.value = v; show(); },
      get value() { return +inp.value; },
    };
  };

  // Row of toggle buttons; onpick(i)
  QM.buttons = (parent, { x, y, items, onpick, active = 0 }) => {
    const box = QM.box(parent, x, y, 10, 10);
    box.classList.add('qm-buttons');
    box.style.width = 'max-content'; box.style.height = 'auto';   // no wrapping when centred near an edge
    const bs = items.map((it, i) => {
      const b = document.createElement('button');
      b.type = 'button';
      if (it.tex) QM.tex(b, it.tex); else b.innerHTML = it.html;
      b.addEventListener('click', () => { onpick(i); b.blur(); });
      box.appendChild(b);
      return b;
    });
    const set = (i) => bs.forEach((b, k) => b.classList.toggle('on', k === i));
    set(active);
    return { el: box, set };
  };

  // Tween a parameter over time: f(t) with t in [0, 1] (eased); returns a stop function
  QM.tween = (ms, f, done, ease = QM.ease) => {
    let stopped = false;
    const t0 = performance.now();
    const tick = (now) => {
      if (stopped) return;
      const t = Math.min(1, (now - t0) / ms);
      f(ease(t));
      if (t < 1) requestAnimationFrame(tick); else if (done) done();
    };
    requestAnimationFrame(tick);
    return () => { stopped = true; };
  };

  // ---------------------------------------------------------------------------
  // Registry and reveal.js wiring
  // ---------------------------------------------------------------------------
  QM.register = (name, factory) => { QM.reg[name] = factory; };

  const stepOf = (slide) => (slide ? slide.querySelectorAll('.fragment.qm-step.visible').length : 0);

  function mount() {
    palette();
    document.querySelectorAll('.qm-widget[data-widget]').forEach((el) => {
      const make = QM.reg[el.dataset.widget];
      if (!make) { console.warn('qm: no widget', el.dataset.widget); return; }
      const opts = { ...el.dataset };
      let inst;
      try { inst = make(el, opts) || {}; } catch (err) { console.error('qm:', el.dataset.widget, err); return; }
      inst.el = el;
      inst.slide = el.closest('section.slide');
      inst.step = -1;
      QM.all.push(inst);
    });
    const sync = (animate) => {
      const cur = Reveal.getCurrentSlide();
      for (const w of QM.all) {
        if (w.slide !== cur || !w.go) continue;
        const k = stepOf(cur);
        if (k !== w.step) { w.step = k; w.go(k, animate); }
      }
    };
    Reveal.on('slidechanged', (e) => {
      for (const w of QM.all) {
        if (w.slide === e.previousSlide && w.leave) w.leave();
      }
      for (const w of QM.all) {
        if (w.slide !== e.currentSlide) continue;
        w.step = -1;
        if (w.enter) w.enter();
      }
      sync(false);
    });
    Reveal.on('fragmentshown', () => sync(true));
    Reveal.on('fragmenthidden', () => sync(true));
    // initial state of every widget (the final one when printing to PDF), then the current slide
    const printing = (Reveal.isPrintView && Reveal.isPrintView()) || /print-pdf/i.test(location.search);
    for (const w of QM.all) {
      if (!w.go) continue;
      const k = printing && w.slide ? w.slide.querySelectorAll('.fragment.qm-step').length : 0;
      w.go(k, false); w.step = k;
    }
    if (printing) return;
    const cur = Reveal.getCurrentSlide();
    for (const w of QM.all) if (w.slide === cur && w.enter) w.enter();
    sync(false);
  }

  const start = () => {
    if (window.Reveal && Reveal.isReady()) mount();
    else window.Reveal.on('ready', mount);
  };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start);
  else start();
})();
