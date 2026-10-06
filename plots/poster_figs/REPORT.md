# Poster figures: report

Run `julia plots/poster_figs/make_poster_figs.jl` (plots env, ~50 s) to regenerate
`hero_A.pdf`, `hero_B.pdf`, `hero_C.pdf`, `fig2.pdf` and their 150 dpi `*_preview.png`.

## Data and scripts reused

| Panel | Source |
|---|---|
| Hero LDOS heatmaps | `data/LDOS/base_partial_szoom.jld2`, `data/LDOS/base_fs_szoom.jld2` (paper Fig. 2), keys `Majo` / `QMajo` |
| Hero real-space wavefunctions | `data/wfs/base_partial.jld2` (χ = 200 nm, V_Z^(2)), `data/wfs/base_fs.jld2` (χ = 1 µm, Φ^(2)), key `QMajo` (paper Fig. 1 a2/d2) |
| Local phases, Fig. 2 left | `data/PD_mu_B/base_partial.jld2` (paper Fig. 1b) |
| Local phases, Fig. 2 middle | `data/PD_mu_flux/base_fs_zoom.jld2` (21–24 meV, paper Fig. 1f) on top of `data_unpublished/PD_mu_flux/base_fs.jld2` (0–60 meV, same model and Φ grid; it only adds the all-trivial region below 21 meV, which the paper drew behind an axis break) |
| Fig. 2 right | Schematic of paper Fig. 4(b) (same parabolas as `figure_skin.jl`), m_r = 1 band only |

Plotting helpers in `plots/plotters/` and the builders in `src/builders/` are reused as-is.

## Recomputed (NEW)

**Hidden quasi-MZM energy E_QMZM(χ)**: `data/E_QMZM/base_fs_szoom.jld2` (also `base_partial_szoom.jld2`).

- Code: `src/calculations/E_QMZM.jl` (`calc_E_chi`), key suffix `_echi` in `src/main.jl`.
  Run on atto (`make CLUSTER=atto ARG=base_fs_szoom_echi run`; one node, partition `most`).
- Method: same setup as `calc_wfs`. The wire is closed, built with `build_barrier` at the
  paper parameters (Φ = 0.65 / 0.88 with Z = 0; V_Z = 3.0 / 1.8 meV), and has length
  L = max(12χ, 15 µm). The SC self-energy depends on ω, so the code solves for the subgap
  pole E = λ(H(ω = E)) by secant iteration, using shift-invert eigenvalues. Eigenvalues of
  H(ω = 0) overestimate E by ≈3.7× in the full shell (Γ_NS = 40Δ₀).
  It also stores ⟨z⟩/χ for the state and its weight in the left half of the wire.
- Plotted as ±E (white dashed) only where the state is localised (⟨z⟩ < 8χ). For smaller χ the
  lowest closed-wire state is the delocalised bulk gap edge at 0.0165 Δ₀, not a Q-MZM.
  One mis-converged point (χ = 214 nm, E = 0) is masked out.
- Consistency check (partial shell): for χ ≥ 75 nm the computed E matches the visible end-LDOS
  branch to within the LDOS energy grid (e.g. 0.0327 vs 0.0327 Δ₀ at 75 nm, 0.0090 vs 0.0093 Δ₀
  at 128 nm). For χ < 45 nm the branch tracking jumps to a delocalised state, so the optional
  partial-shell overlay was **not** drawn. On top of the bright branch it would only add clutter.

**Trajectory ticks (Fig. 2)**: computed in the plotting script, no new data (see mapping below).

## μ(z) mapping

- **Partial shell:** Eq. (A2), μ(z) = μ_bulk (1 − e^{−z/χ}), exactly the `build_barrier` potential.
- **Full shell:** the Bessel barrier U(z, r) of `build_barrier` (Eq. A1, N = 100 terms),
  projected on the radial density of the m_J = 0, m_r = 1 mode. That mode is the electron
  eigenstate of `hSM` at k_z = 0, Φ = 0.88, Z = 0, with band bottom at 21.8 meV. The mapping is
  μ_eff(z) = μ_bulk − ⟨U(z, r)⟩. At large z this gives ≈ μ_bulk(1 − 0.85 e^{−z/χ}). The pure ν = 1
  term would give 1 − e^{−z/χ} and shift the boundaries by ~0.15χ. μ_eff(0) = 0.06 μ_bulk, not 0,
  because U vanishes at the outermost site r = R.
- Resulting local phases (used in hero column 1 and in Fig. 2):
  - **Partial, V_Z^(2):** Topo for 0 < z < 1.86χ, Triv beyond (μ_c = 0.844 μ_bulk).
  - **Full, Φ^(2):** skin for 0 < z < 3.50χ (μ^ts = 0.974 μ_bulk), Topo for 3.50χ < z < 7.01χ
    (upper edge 0.9992 μ_bulk), Triv beyond.

  The data wavefunctions agree: the full-shell left Q-MZM peaks at 3.68χ and the right one at
  6.87χ. The partial-shell right Q-MZM peaks at 2.3χ.
- z < 0 ("Insulator") is the uncovered tunnel-barrier section, drawn schematically as in the
  paper.

## Hero real-space column (revision 2, hero_B is the chosen variant)

- New "Device" column with the 3D renders from paper Fig. 1(a,d) (`plots/sketches/*.png`).
- Above each real-space strip is the longitudinal cut from Fig. 1(a,d), sharing the z/χ axis:
  probe, bare SM, and the SC starting at z = 0 (on both sides for the full shell), plus B.
  It replaces the probe triangle glyph.
- The black line is now the band bottom eφ_g(z) under a labelled μ line. Its zero coincides
  with the zero of the |Ψ|² curves, and μ_bulk is drawn at 1.35× the wavefunction height to
  exaggerate the barrier. For z ≥ 0 it is 1 − μ(z)/μ_bulk, using the mappings above. For z < 0 it is a
  schematic barrier: a smooth quartic peaking at ≈1.5 μ_bulk, matched in value and slope at
  z = 0, so the Insulator region is where it rises above μ.
- Wavefunctions are labelled |Ψ_L|² and |Ψ_R|² and drawn at 4.5 pt; the barrier is 4 pt.
- Phase labels are spelled out: Insulator, Topological, Trivial, and **Trivial skin**. "Skin"
  never appears on its own in either figure.

## Hero MZM / Q-MZM strips (revision 4)

- The hero is now **771 × 300 mm** (2186 × 850 pt), 25 % taller than the original spec.
- Each real-space cell has the device cut on top, then an **MZM** strip (V_Z^(1) / Φ^(1)), then a
  **Q-MZM** strip (V_Z^(2) / Φ^(2)), sharing the z/χ axis.
- MZM strips use `data/wfs/*.jld2`, key `Majo`. Only the probe-end Majorana is drawn; its
  partner sits at the far end of the simulated wire (z ≈ 100χ).
- **Partial shell, V_Z^(1):** topological along the whole wire.
- **Full shell, Φ^(1):** trivial skin for 0 < z < 3.42χ (μ^ts = 0.972 μ_bulk at Φ = 0.65), then
  topological. The barrier projection uses the m_J = 0, m_r = 1 radial mode at Φ = 0.65.
- The χ dimension bar now sits in the full-shell MZM strip; e·φ_g(z) is labelled only in the
  MZM strips. "Insulator" is 20 pt to fit under the barrier peak.

## Hero regime divider (revision 3)

- A white dashed line at χ* = 18.9 nm sits in both full-shell LDOS panels. χ* is the χ beyond
  which the end signal stays below 1 % of its maximum in both panels (computed in
  `χ_vanish` from the LDOS data: 18.9 nm true MZM, 18.4 nm Q-MZM).
- Labels: "sharp end: probe works" (left) and "smooth end: trivial skin hides all" (right).
- The ✗ / ✓ carry "ZBP ⇒ ?" (partial shell: a ZBP does not identify the state) and "ZBP ⇏ Q-MZM" (full shell: a ZBP cannot come from a Q-MZM).

## Hero variant C (vertical layout)

- `hero_C.pdf`, 771 × 240 mm (2186 × 680 pt), the original hero height. Left half: partial shell.
  Right half: full shell. Each half has a header (3D render, shell name and longitudinal cut)
  over two columns, "True MZM" and "Quasi-MZM", each with the real-space strip above its
  end-LDOS heatmap. Each half also has its own LDOS colorbar (same normalisation).
- To save space, the axis labels sit inline, in the tick-label band:
  - z goes between the 2χ and 4χ ticks (partial) or the 4χ and 6χ ticks (full). The strip
    ticks read 0, 2χ, 4χ, … in all hero variants.
  - ω/Δ₀ goes at ω = 0, left of the "0" tick label, between the ± tick labels.
  - χ (nm) stays as a normal x label below the LDOS panels.
- LDOS data, normalisation, energy ranges and annotations are the same as in hero_B
  (`ldos_overlays!` is shared).
- The partial-shell strips use z/χ ∈ [−1, 6] and the full-shell strips [−1, 9]. On the common
  range, the "Topological" label does not fit the narrow partial-shell Q-MZM band
  (0 < z < 1.86χ). The partial shell has no structure beyond ≈5χ.

## Real-space strips (revision 4, all hero variants)

- Wavefunctions: |Ψ_L|² is navy (#23427F, lighter than the black barrier) and |Ψ_R|² is orange
  (#E07A00). Both contrast with the red-tint topological, green-tint skin and grey regions.
- Both are drawn over the whole wire, from z = 0 to the panel edge, including where they
  vanish. The true-MZM strips show only the end Majorana |Ψ_L|². The wire is semi-infinite,
  so the simulated partner at z ≈ 100χ is not drawn.
- The μ line and its label are dashed grey (#606060), distinct from the black eφ_g(z) and
  from the orange |Ψ_R|².
- χ bar in both true-MZM strips. Full shell: on the curve, as before. Partial shell: at the
  top left, because the |Ψ_L|² oscillations fill 0 < z < χ.

## Fig. 2 (revision 4)

- Each trajectory is labelled MZM or Q-MZM: vertical text on its left, reading up from μ = 0.
  The labels go on the left because the χ tick labels sit on the right.
- In the full-shell panel, "Trivial skin" is set on two lines to leave room for these labels.
- The μ_bulk line and label use the hero's μ grey (#606060).
- Band-filling panel: "CdGMs" label with arrows to three white states on the left parabola.

## Numbers for the poster text

- **Full-shell end-LDOS signal vanishes** (Q-MZM, Φ^(2), z = 0, m_J = 0). The peak LDOS in
  |ω| < 0.2Δ₀ falls below 10 % of its maximum at **χ ≈ 10 nm** and below 1 % at **χ ≈ 18 nm**.
  The true-MZM panel behaves the same: 11 nm and 19 nm.
- **Q-MZM splitting below 0.01 Δ₀:** at **χ ≈ 220 nm**. That is where the Q-MZM first appears as
  a bound state separate from the bulk gap edge (0.0165 Δ₀), and it already has E = 3.3×10⁻³ Δ₀.
  Further down:

  | E below | from χ |
  |---|---|
  | 10⁻³ Δ₀ | 356 nm |
  | 10⁻⁴ Δ₀ | 628 nm |
  | 10⁻⁵ Δ₀ | 915 nm |
  | 10⁻⁶ Δ₀ | 1.2 µm |

  At χ = 1 µm, E = 4.6×10⁻⁶ Δ₀ ≈ 1 neV. So there is a window of more than two decades in χ
  (≈20 nm – 3 µm) with no end signal, and over most of it the hidden state is pinned to zero
  energy.

## Compromises and flags

1. **Shared colour scale.** All four heatmaps use colorrange (0, 0.01), which is the paper's
   full-shell scale, and `highclip`. The partial-shell row saturates (its peaks reach 1.5–1.8),
   so its lines look a bit thicker than in the paper, but no panel is unreadable. With the
   paper's partial-shell scale (0.1), the full-shell Q-MZM small-χ feature would drop to 8 % and
   nearly vanish. Note that partial (1D, one site) and full-shell (14 radial sites summed) LDOS
   come from different models, so their absolute units aren't strictly comparable.
2. **Energy axes differ between rows.** The partial-shell row spans ±0.2 Δ₀. The full-shell
   row is zoomed to ±0.07 Δ₀ because the partial-shell true-MZM line is ≈3× wider on the shared
   colour scale (0.026 vs 0.0087 Δ₀ at 20 % of the scale), so both zero-energy lines now look
   equally thick. As a side effect, the hidden Q-MZM (≤ 3.3×10⁻³ Δ₀, i.e. ≤ 5 % of the
   half-range) appears as a small fork at χ ≈ 220 nm that then collapses onto zero. The
   ω = 0 guide lines were removed.
3. **Fig. 2 μ axes carry no scale.** The partial-shell panel is linear in μ/μ_bulk. The
   full-shell panel uses a schematic axis, because on a linear one its topological window
   (μ^ts → μ_bulk, only 0.026 μ_bulk wide) is invisible: 0 → μ^ts is compressed into the
   lower half and μ^ts → μ_bulk is stretched over the upper half (smooth piecewise-linear map,
   `μaxis`; μ = 0 and μ_bulk keep their positions). z = χ therefore sits at about half its
   linear height in the full shell, so the χ marks are not at equal heights in the two panels.
   The full-shell PD is resampled from the data with linear interpolation in μ.
   In the band-filling panel, the trivial-skin shading starts at the band bottom.
   Hero LDOS panels are labelled V_Z = V_Z^(1,2) and Φ = Φ^(1,2); the real-space sketches
   carry the Q-MZM value (V_Z^(2), Φ^(2)) next to B.
4. **Arrow colours.** The arrows are coloured piecewise by phase (Ins dark grey, skin green
   7 pt, Topo red, Triv black) instead of the paper's green/blue per-case colours. The cases are
   identified by the x tick labels V_Z^(1,2) and Φ^(1,2). Ticks z = χ, 2χ, 3χ sit on every
   arrow and are labelled on one arrow per panel.
5. **Text size.** All base text is ≥ 22 pt. Sub- and superscripts in math labels (μ_bulk,
   V_Z^(1), ω/Δ₀, m_J) render at ~70 % of the base size, i.e. ≈15–18 pt.
6. **Page size.** Cairo rounds to whole points: 2186 × 680 pt (target 2185.5 × 680.3) and
   1057 × 425 pt (target 1057.3 × 425.2), so the error is ≤ 0.2 mm.
7. **Fonts.** TeX Gyre Heros for text and New Computer Modern for math (two families), all
   embedded as text (checked with `pdffonts`).
8. **Wavefunction colours.** Navy (left) and orange (right), see revision 4.
