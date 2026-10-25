# Talk: web version (Quarto + reveal.js)

Contributed talk at the Joint ICTP–WE Heraeus College on Advances in Topological Quantum
Matter, Trieste, 30 October 2026 (20 + 5 min). This is the HTML version of the deck, with
interactive figures driven by the data of the paper. It also holds the reusable slide
template (`_extensions/qudyma`).

## Build and present

```bash
sh build.sh           # figures, then talk-standalone.html (one self-contained file) and talk.html
sh build.sh publish   # also copies the standalone deck to PhD/Presentations/2026_10_ICTP
quarto preview talk.qmd   # live preview while editing (local server, works offline)
```

`talk-standalone.html` carries everything (fonts, KaTeX, d3, data, images, ~16 MB): open it
in Chrome or Firefox, no internet needed. Keys: arrows or space to advance, `F` full screen,
`S` speaker view with notes and timer, `M` menu, `Esc` overview, `B` black screen, `?` help.
The speaker view opens a second window; if the browser blocks it from a `file://` page,
present from `quarto preview talk.qmd` instead.

PDF backup: open `talk.html?print-pdf` in Chrome and print to PDF (landscape, no margins,
background graphics on). In print mode every interactive figure shows its final state.

## What the slides show

| Slide | Figure | Data |
|---|---|---|
| Nanowire turns topological | BdG bands vs V_Z, phase diagram, Z₂ index (`olbands`) | analytic, paper's partial-shell parameters with constant Δ = Δ0 |
| ZBP at the end; false positive | end LDOS vs V_Z for χ = 1, 50, 100, 200 nm (`ldos-vb`) | χ = 200 nm published (`data/LDOSvB`); 1, 50, 100 nm illustrative (`slides/data`) |
| Smooth end; trivial skin | μ(z) path through the phase diagram and local phases along the wire (`path`) | `data/PD_mu_B`, `data/PD_mu_flux` (+ `data_unpublished`, as the poster), `data/wfs` |
| Quasi-MZM pair | wavefunctions while χ grows, splitting E(χ) (`qmzm`) | illustrative χ sweep (`julia/calc_partial_sweeps.jl`); E from the end LDOS and `data/E_QMZM` |
| Little–Parks | phase winding and shell gap vs flux (`lp`) | illustrative (`slides/data/lp_lobes.jld2`) |
| m_J sectors | sectors, particle–hole pairing, symmetry classes (`blocks`) | schematic |
| Two classes at zero energy | DOS split into m_J ≠ 0 and m_J = 0 (`sectors`) | `data/DOS/base_fs_Zs.jld2` (paper Fig. 1g) |
| Who fills first | band filling, partial vs full, and the wire strip (`filling`) | schematic, as paper Fig. 4(b) |
| Gate potential | eφ_g(r, z) and μ(z) (`potential`) | Bessel kernel of `src/builders/barrier.jl` |
| Quasi-MZMs inside | m_J = 0 DOS near zero energy (`dos-zoom`) | `data/DOS/base_fs_zoom.jld2` (paper Fig. 1h) |
| No false positives; disorder | end LDOS vs χ (`ldos-chi`), hidden pair energy | paper Figs. 2 and 3 (`data/LDOS`); hidden energy `data/E_QMZM` (poster) |
| One length scale | E(χ) and the visible / pinned windows (`window`) | paper Fig. 2 data and `data/E_QMZM` |

Static figures (cartoons, experiment vs theory, backups) are copied from `slides/figs` and
`plots/figures` by `collect_figs.sh`.

## Layout

| Path | What |
|---|---|
| `talk.qmd` | The deck: slides, fragments and speaker notes |
| `_extensions/qudyma/` | The template (format `qudyma-revealjs`): theme, title slide, kickers, Montserrat and KaTeX bundled |
| `assets/js/qm.js` | Runtime of the interactive figures (registry, fragment steps, axes, heat maps, sliders) |
| `assets/js/w_*.js` | One file per family of figures |
| `assets/css/` | Styles of the figures (`qm.css`) and of this talk (`talk.css`) |
| `assets/data/` | Data of the figures, written by `julia/export_data.jl` |
| `assets/img/` | Device renders and the QR code of the paper |
| `assets/private/`, `assets/figs/` | Photos and logos (not tracked, the repo is public); copied figures (not tracked) |
| `julia/` | `export_data.jl` (data → JS) and `calc_partial_sweeps.jl` (illustrative calculations) |

## Data

```bash
julia --project=. slides/quarto/julia/calc_partial_sweeps.jl   # repo root env, a few minutes
julia slides/quarto/julia/export_data.jl [name ...]           # plots env, through slides/make_figs.jl
```

`export_data.jl` reads the published data with the helpers of `slides/make_figs.jl` and
writes `assets/data/<name>.js` (each sets `QMD.<name>`); heat maps are 8-bit over a fixed
colour range. Nothing of the paper is recomputed.

## Interactive figures

A figure is a div with an explicit size:

```markdown
::: {.qm-widget data-widget="path" data-shell="partial" style="width:1440px;height:540px"}
:::

[]{.fragment .qm-step}
[]{.fragment .qm-step}
```

Each `.qm-step` fragment on the slide moves the figure to its next preset state (with an
animation); text fragments can carry `.qm-step` too. Going back runs the steps backwards.
Sliders, buttons and hovering stay live for questions. New figures register with
`QM.register(name, (el, opts) => ({ go(step, animate) {...} }))` in a new
`assets/js/w_*.js`, added to `assets/includes/after-body.html`.

## The template

`_extensions/qudyma` can be copied into any talk folder; then `format: qudyma-revealjs`.
It sets a 1600 × 900 canvas, the palette (CSIC red, ink, the physics colours as `--qd-*`
CSS variables), Montserrat and local KaTeX, so decks work offline.

- Title slide fields: `title`, `author` (with `attributes: equal-contributor`),
  `affiliation`, `event`, `venue`, `date`, `paper`, `paper-url`, `hero` (list of
  `{src, caption, class}`; `class: wide` spans the panel), `logos`, `title-note`, `footer`.
- Parts: `# Title {.part data-num="01" data-kicker="01 · Short name" data-sub="..."}`. Every
  following slide shows the part's kicker above its title (override with
  `{data-kicker="..."}`, hide with `.no-kicker`).
- Slide titles are assertions. Classes: `.no-rule`, `.no-chrome` (no footer or number).
- Blocks: `.key` take-away (`.green`, `.navy`, `.orange`, `.plain`), `.lead`, `.eq`,
  `.refs` (bottom, grey; write your own name in bold), `.figcap`, `.card`, `.stack`
  (overlays layered figures), `.avatars`/`.avatar`, `.photo-map`, `.conc`.
- Inline: `[class D]{.chip .red}` (also `.green`, `.navy`, `.ink`, `.red-soft`, …), `.muted`,
  `.small`, `.smaller`, `.tiny`, `.red`, `.green`, `.navy`, `.hl-red`, `.hl-green`.
- Fragments: reveal's own, plus `.fade-up` and `.dim-out`.
