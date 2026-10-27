// QUDYMA talk theme: small reveal.js plugin.
//  - Kickers: every slide after a part divider (# Title {.part}) gets that part's label as
//    its kicker (data-kicker), unless it sets its own. The label is the part's
//    data-kicker, or its data-num and title.
//  - Chrome: footer and slide number are hidden on the title slide, on part dividers and
//    on slides with the class .no-chrome.
//  - Logo: the document logo (YAML `logo:`) is placed in the top-right corner of every
//    content slide, in line with the kicker, instead of Quarto's corner of the window.
//  - Math: any KaTeX span left unrendered is rendered here. Standalone (embed-resources)
//    builds need it: there Quarto loads KaTeX dynamically, which is not embedded, while the
//    template also loads it statically (katex-static.html).
window.RevealQudyma = function () {
  function partLabel(part) {
    if (part.dataset.kicker) return part.dataset.kicker;
    const h = part.querySelector('h1');
    const title = h ? h.textContent.trim() : '';
    return part.dataset.num ? `${part.dataset.num} · ${title}` : title;
  }
  function setKickers(deck) {
    let label = null;
    for (const s of deck.getSlides()) {
      if (s.id === 'title-slide') continue;
      if (s.classList.contains('part')) { label = partLabel(s); continue; }
      if (s.classList.contains('no-kicker')) { delete s.dataset.kicker; continue; }
      if (!s.dataset.kicker && label) s.dataset.kicker = label;
    }
  }
  function chrome(slide) {
    const hide = !slide || slide.id === 'title-slide' || slide.classList.contains('part') ||
      slide.classList.contains('no-chrome');
    document.body.classList.toggle('qd-hide-chrome', hide);
  }
  function placeLogo(deck) {
    const logo = document.querySelector('.reveal .slide-logo');
    if (!logo) return;
    logo.style.display = 'none';
    for (const s of deck.getSlides()) {
      if (s.id === 'title-slide' || s.classList.contains('part') || s.classList.contains('no-chrome') ||
        s.classList.contains('no-logo')) continue;
      const img = document.createElement('img');
      img.src = logo.src;
      img.alt = '';
      img.className = 'qd-slide-logo';
      s.appendChild(img);
    }
  }
  function renderMath(deck) {
    if (!window.katex) return;
    let n = 0;
    document.querySelectorAll('span.math').forEach((el) => {
      if (el.querySelector('.katex')) return;
      try {
        katex.render(el.textContent, el, { displayMode: el.classList.contains('display'), throwOnError: false });
        n++;
      } catch (err) { /* leave the TeX source visible */ }
      el.classList.replace('math', 'math-done');      // so a late loader does not render it twice
    });
    if (n) deck.layout();
  }
  return {
    id: 'qudyma',
    init: function (deck) {
      const math = () => renderMath(deck);
      if (document.readyState === 'complete') math(); else window.addEventListener('load', math);
      deck.on('ready', (e) => { setKickers(deck); placeLogo(deck); chrome(e.currentSlide); });
      deck.on('slidechanged', (e) => chrome(e.currentSlide));
    },
  };
};
