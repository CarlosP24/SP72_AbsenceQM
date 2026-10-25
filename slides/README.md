# Talk: Joint ICTP–WE Heraeus College on Advances in Topological Quantum Matter

Contributed talk, Trieste, 30 October 2026 (20 + 5 min). Figures and equations for the
deck, built from the published data of this repository.

## Contents

| Path | What |
|---|---|
| `style.jl` | Slide style: Montserrat text, New Computer Modern math, poster palette, figure sizes in inches on a 13.33 × 7.5 in slide |
| `make_figs.jl` | All figures, at their final size on the slide. Step-by-step builds are exported as layers (same canvas, transparent background) |
| `make_equations.py` | Equations, typeset with LaTeX at their final size; sources in `equations/sources.json` |
| `build_deck.py` | Builds the deck on the SuperSemi (June 2026) template: native text in Montserrat, SVG figures with PNG fallback, Morph transitions, click builds, speaker notes |
| `calc_sharp_ldos.jl` | Illustrative intro calculation: end LDOS vs V_Z of the partial-shell wire with an abrupt end (χ = 1 nm) |
| `calc_qmzm_wfs.jl`, `calc_qmzm_dos.jl` | Illustrative intro calculations (slide 5): quasi-MZM pair and DOS vs V_Z of the partial-shell wire for sharper ends than the published χ = 200 nm (χ = 20–100 nm and 50 nm), same routines as `src/calculations` |
| `calc_cdgm_bands.jl` | Illustrative intro calculation: hollow-core bands and end LDOS (CdGM analogs), reusing the thesis builder in `PT_Thesis/PT3_CdGM` |
| `figs/`, `equations/` | Outputs (`.svg` placed in the deck, `.pdf` vector copies, `.png` fallbacks) |
| `quarto/` | Web version of the deck (Quarto + reveal.js) with interactive figures, and the reusable template; see `quarto/README.md` |
| `data/` | Results of the illustrative calculations |

No result of the paper is recomputed: every result figure reads `data/` (and, as the
poster, `data_unpublished/PD_mu_flux/base_fs.jld2`). The CdGM slide also reads the
Deng et al., PRL 134, 206302 (2025) data kept in `PT_Thesis/PT3_CdGM/data`.

## Regenerate

```bash
julia --project=. slides/calc_sharp_ldos.jl                       # ~1 min
julia --project=. slides/calc_qmzm_wfs.jl                         # seconds
julia --project=. slides/calc_qmzm_dos.jl                         # ~1 min
julia --project=<PhD>/PT_Thesis/PT3_CdGM slides/calc_cdgm_bands.jl  # seconds
julia slides/make_figs.jl [prefix ...]                            # plots environment, ~2 min
python3 slides/make_equations.py                                  # needs pdflatex, pdftocairo
python slides/build_deck.py [out.pptx]                            # python-pptx, lxml; reads slides/assets
```

`assets/` (photos and logos from earlier decks) and `wip/` (review sheets) are not
tracked. The deck itself is kept in `PhD/Presentations/2026_10_ICTP/`.
