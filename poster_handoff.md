# Handoff: poster figures for "Absence of Quasi-Majorana False Positives in Full-Shell Hybrid Nanowires"

**Paper:** C. Payá, C. Robles, P. San-Jose, E. Prada, *Phys. Rev. Lett.* **137**, 096606 (2026), doi:10.1103/w9tp-3bbq
**Venue:** Joint ICTP–WE Heraeus College on Advances in Topological Quantum Matter, Trieste, 12–30 Oct 2026
**Poster:** A0 portrait, laid out in Affinity. Figures are placed as vector PDFs into fixed frames.
**Your job:** render two figures (the hero and Fig. 2) with the paper's existing Julia / Makie / Quantica.jl / FullShell.jl pipeline, adapted as described below. Reuse existing data and scripts wherever possible. Recompute only what is marked **NEW**.

---

## 1. Audience and message (why the figures look like this)

The audience is broad: PhD students and postdocs in topological matter, most of them not nanowire specialists. Experts on quasi-Majoranas (Brouwer, Meidan, Akhmerov) will also be present. Every figure must read from about 1.5 m without the caption.

The poster's single message is:

> In full-shell nanowires, the smooth potential that creates Majorana impostors (quasi-MZMs) also hides them, behind a trivial skin at the wire's end.

- The **hero** shows *that* this is true: the quasi-MZM produces a zero-energy peak (ZEP) in the partial shell, but no peak in the full shell.
- **Fig. 2** shows *why*: in full shells, μ(z) must cross a trivial region before reaching the topological phase, because the m_J = 0 mode has a threshold μ^ts.

---

## 2. Global format rules (apply to both figures)

| Item | Requirement |
|---|---|
| Output format | Vector **PDF**, rendered with CairoMakie. Also provide a PNG preview at 150 dpi. |
| Physical size | Exact, in mm (see each figure). Render at 1:1 so that `fontsize` values are literal points on the printed poster. |
| Size setup | `mm = 72/25.4`; `Figure(size = (W*mm, H*mm), figure_padding = 4mm)`; `save("x.pdf", fig; pt_per_unit = 1)` |
| Minimum text | **20 pt absolute minimum** for anything (template rule). Target 22 pt for tick labels, 26 pt for axis labels, 28–30 pt for row and column titles. |
| Lines | Data lines at least 2.5 pt. Wavefunctions 3 pt. Axis spines 1.5 pt. Guide lines (ω = 0) 1 pt. |
| Font | Clean sans-serif matching the poster body (the Makie default TeX Gyre Heros is acceptable). Math via `L"..."` (LaTeXStrings) is fine. Don't mix more than two fonts. |
| Background | White or transparent, with no outer frame. The poster supplies margins. |
| Panel letters | **None.** The poster refers to the figures by column and row titles, not (a), (b), etc. |
| No in-figure captions or titles | Captions are set in Affinity, so don't add a figure title or a long legend paragraph. Short in-panel annotations are allowed where specified. |
| Ticks | Few, round values: at most 4–5 ticks per axis. Use a log axis for χ with ticks at 1, 10, 100, 1000 nm. |
| Colormap | Keep the paper's LDOS colormap, with **one shared colorbar** per figure. Normalise all heatmaps identically. |

### Palette (must match the poster template)

The Affinity file uses these Pantone swatches. The hex values are standard approximations; if the repo has an exact brand palette, use that.

| Role | Swatch | Hex (approx.) |
|---|---|---|
| Topological region, poster accent | PANTONE 186 C (CSIC red) | `#C8102E`. Use a ~35 % tint (`#EE9DA9`-ish) for region fills so data stays readable on top. |
| Trivial skin (**the protagonist**) | PANTONE 3415 C (green) | `#007749`. Use a ~30 % tint for fills and the full colour for outlines and labels. |
| Insulating region | neutral grey | `#BDBDBD` |
| Trivial bulk region | white or very light grey | `#F4F4F4` |
| Left-localised quasi-MZM / MZM wavefunction | same red as the paper | |
| Right (interior) quasi-MZM wavefunction | same green as the paper, but make sure it's distinguishable from the skin tint (darker, or a different hue such as `#2E7D32`) | |
| Hidden quasi-MZM energy (NEW overlay) | white dashed line, 2.5 pt, on top of the heatmap | |

Region colours must be identical in the hero and in Fig. 2.

---

## 3. Hero figure: **771 × 240 mm** (landscape strip, aspect ≈ 3.2 : 1)

### Concept

This merges paper Fig. 1(a2, d2) with Fig. 2(a–d) into a **2-row × 4-column grid**.

- **Rows:** top = partial shell, bottom = full shell. Put the row titles as rotated text in a narrow left gutter: "Partial shell" and "Full shell", 30 pt, bold.
- **Columns:** each has a title on top, 28 pt.

| Col | Title | Content | Relative width |
|---|---|---|---|
| 0 | (gutter) | row titles | 0.04 |
| 1 | "Real space" | phase strip and wavefunctions, quasi-MZM case | 0.30 |
| 2 | "True MZM" | end LDOS vs (χ, ω), MZM case | 0.22 |
| 3 | "Quasi-MZM" | end LDOS vs (χ, ω), quasi-MZM case, **plus NEW overlay** | 0.22 |
| 4 | — | shared LDOS colorbar (vertical, spanning both rows) | 0.03 |

Optional verdict column: see Variant A/B below.

### Column 1: real-space strip (adapt Fig. 1(a2) and (d2))

- x axis: **z/χ** from about −0.5 to 6 (choose a range in which both rows show the full structure). Use the **same x range in both rows**.
- Background: shade the x-range of each local phase using the palette. The phases are determined locally from μ(z) and the phase diagram, exactly as in the paper.
  - Partial shell (Q-MZM parameters, V_Z = V_Z^(2)): Ins | Topo | Triv.
  - Full shell (Q-MZM parameters, Φ = Φ^(2)): Ins | **Triv skin** | Topo | Triv.
- Put short phase labels inside each band, near the top: "Ins", "Topo", "Triv", and "**skin**" (in skin-green, bold).
- Overlay the **two quasi-MZM wavefunctions** |ψ|² (red: left, green: right). Normalise each to its own maximum (footnote [83] says they're not to scale; the caption will say so). Plot the y axis without numbers, labelled "|ψ|² (arb.)" or with no label.
- Overlay μ(z)/μ_bulk as a thin black line, as in the paper's schematic.
- Draw a **probe glyph** at z = 0: a small downward triangle or tip above the axis, labelled "probe" (22 pt).
- Goal: the eye sees that in the full shell, the teal skin pushes both wavefunctions away from the probe.

### Columns 2 and 3: end LDOS heatmaps (adapt Fig. 2(a–d))

- Same data and parameters as paper Fig. 2, i.e. the m_J = 0 sector at z = 0.
  - Partial shell: V_Z^(1) (MZM) and V_Z^(2) (Q-MZM), the green and blue marks of Fig. 1(c).
  - Full shell: Φ^(1) and Φ^(2), the green and blue marks of Fig. 1(h).
- x axis: χ in nm, log scale, 1–1000, label `χ (nm)`. Show the x label only on the bottom row; hide the top row's tick labels with `linkxaxes!`.
- y axis: ω/Δ₀ from −0.2 to 0.2, ticks at −0.2, 0, 0.2. Show the y label only on column 2.
- Draw a thin white guide line at ω = 0 in every heatmap.
- **Use one colour normalisation for all four heatmaps**, so that the absence of signal in the full-shell quasi-MZM panel is honest. If one panel saturates, clip it (`highclip`) rather than rescaling per panel. **Flag in your report if a shared scale makes any panel unreadable.**
- **NEW: hidden-state overlay (full shell, Q-MZM panel only).** Compute the energy of the lowest quasi-MZM eigenstate as a function of χ, from the spectrum (eigenvalues of the semi-infinite or long-wire Hamiltonian; the DOS integrated over the μ(z) region, as in Fig. 1(h), also works). Plot ±E_QMZM(χ) as a **white dashed line** over the LDOS heatmap.
  - This is the key adaptation: it shows the quasi-MZM *exists* and goes to zero energy while the end-LDOS shows nothing.
  - Add a short annotation inside the panel, in white, 22 pt: "Q-MZM exists, invisible at end".
  - Optionally add the same overlay to the partial-shell Q-MZM panel for symmetry. It should then sit on top of the visible branches, which is a nice consistency check. Include it only if it doesn't clutter.

### Variants to deliver

- **`hero_A.pdf`:** as above, plus a 5th column "Verdict" (relative width 0.12, placed before the colorbar). It holds one rounded box per row:
  - Top row: red fill, white text, "False positive / ZEP looks like an MZM".
  - Bottom row: green fill, white text, "No false positive / impostor buried by skin".
  - Text at 26 pt or more.
- **`hero_B.pdf`:** no verdict column; the freed width is redistributed to columns 1–3. Put a large ✗ (red) in the top-right corner of the partial-shell Q-MZM panel and a ✓ (green) in the full-shell Q-MZM panel, at about 40 pt.

---

## 4. Fig. 2: **373 × 150 mm** (aspect ≈ 2.5 : 1). "Why the skin appears"

### Layout: 1 row × 3 panels

| Panel | Title (26–28 pt) | Relative width |
|---|---|---|
| left | "Partial shell" | 0.37 |
| middle | "Full shell" | 0.37 |
| right | "m_J = 0 threshold" | 0.26 |

### Left and middle: phase diagrams with μ(z) trajectories (adapt Fig. 1(b) and 1(f))

- Left: partial-shell (V_Z, μ) phase diagram. Use x = V_Z / V_Z^c (or V_Z in meV if cleaner).
- Middle: full-shell (Φ/Φ₀ within the n = 1 lobe, μ) phase diagram at the ⟨α⟩ of the blue dot in Fig. 1(e).
- **Both y axes normalised to μ/μ_bulk**, range about [−0.2, 1.1], so the two panels share a vertical scale; link the y axes. Mark μ_bulk with a dashed horizontal line labelled "μ_bulk".
- Shade regions with the palette: Ins grey, Triv white, Topo red tint.
- **Trajectories:** draw the path of μ(z) as the probe moves inward, i.e. a vertical arrow from μ = 0 up to μ_bulk at fixed field or flux. Draw two arrows per panel, as in the paper: the MZM case (green arrow, at V_Z^(1) / Φ^(1)) and the Q-MZM case (blue arrow, at V_Z^(2) / Φ^(2)).
  - **NEW:** colour each arrow *piecewise* by the phase it traverses. In the full-shell panel, the segment that crosses the trivial region near the bottom is drawn in **skin-green and thicker** (about 6 pt), labelled "skin". The partial-shell arrows go straight from Ins to Topo, with no skin segment.
  - Put small tick marks on the arrows at z = χ, 2χ, 3χ, using the μ(z) mapping the code actually uses: Eq. (A2) for the partial shell. For the full shell, use whatever effective μ(z) defines the local phase in the code, e.g. U(R) − eφ_g(R⁻, z) or the ν = 1 term of Eq. (A1). **State in your report which mapping you used.**
- Label the full-shell threshold μ^ts on the y axis (green tick and label).

### Right: band-filling sketch (adapt Fig. 4(b), m_r = 1 only)

- E vs m_L (integer), normal state, k_z = 0, Φ = 0.5Φ₀, realistic SOC (the paper's Fig. 4(b) case; **drop the m_r = 0 / strong-SOC version**).
- Highlight the m_J = 0 pair in red and draw the others grey.
- Draw a horizontal green line at μ^ts_{m_r=1}, labelled "μ^ts", and shade the band below it with the light skin-green tint, labelled "trivial skin".
- No y tick numbers needed; label the axes "m_L" and "E".

---

## 5. Parameters (from paper Appendix C; use the repo's actual parameter sets)

**Common:** m* = 0.023 m_e, Δ₀ = 0.23 meV, Pauli limit V_C = 2 V_Z^c.

**Partial shell:** μ_bulk = 2 meV, α = 40 meV·nm, Γ_NS = 3Δ₀. Fig. 1(a–c) uses χ = 200 nm.

**Full shell:** μ_bulk = 22.8 meV, ΔU = 60 meV, ⟨α⟩ = 7 meV·nm, Γ_NS = 40Δ₀, R = 70 nm, d = 10 nm, ξ_d = 70 nm, g = 10. Fig. 1(d–h) uses χ = 1 µm.

**Fig. 2 (paper) / hero LDOS:** the green and blue marks of Fig. 1(c) and 1(h). For the hero real-space column, use the same field or flux as the Q-MZM heatmap and the χ values of Fig. 1 (200 nm partial, 1 µm full). Plotting in z/χ makes the two rows comparable.

---

## 6. Deliverables

```
poster_figs/
  hero_A.pdf        771 × 240 mm, with verdict column
  hero_B.pdf        771 × 240 mm, ✓/✗ variant
  fig2.pdf          373 × 150 mm
  *_preview.png     150 dpi previews of each
  make_poster_figs.jl   script that regenerates all of the above from repo data
  REPORT.md         short notes (see below)
```

`REPORT.md` should contain:
- which data files and scripts were reused and what was recomputed (especially the NEW hidden-state overlay and the trajectory ticks);
- the μ(z) mapping used for the full-shell trajectory;
- any compromise you made (e.g. shared colour scale clipping, changed axis ranges);
- the actual χ at which the full-shell end-LDOS signal vanishes and the χ at which the Q-MZM splitting falls below ~0.01Δ₀. These numbers will be quoted in the poster text.

## 7. Acceptance checklist

- [ ] PDF page size is exactly 771 × 240 mm (hero) and 373 × 150 mm (Fig. 2). Check with `pdfinfo`: 2185.5 × 680.3 pt and 1057.3 × 425.2 pt.
- [ ] No text below 20 pt anywhere, including colorbar ticks and annotations.
- [ ] One shared colorbar per figure, with identical normalisation across heatmaps.
- [ ] Region colours are identical between the hero and Fig. 2, and the skin is clearly the green accent.
- [ ] Hidden quasi-MZM dashed line present in the full-shell Q-MZM panel.
- [ ] No panel letters, no figure titles, no captions inside the figures.
- [ ] Fonts embedded and text kept as text (not outlined) in the PDF.
- [ ] Previews look legible when the PNG is viewed at about 25 % zoom (a proxy for reading at 1.5 m).

## 8. Captions (set in Affinity, for your reference only; do not render)

**Hero:** End-of-wire LDOS versus confinement smoothness χ for a true MZM and a quasi-MZM, in partial- and full-shell wires (wavefunctions not to scale). In full shells the quasi-MZM forms (dashed) but is buried behind a trivial skin, so it never produces a zero-bias peak.

**Fig. 2:** μ(z) traces a path through parameter space as it rises from the barrier. Full shells require μ > μ^ts before the m_J = 0 mode can turn topological, so a trivial skin always separates probe and Majorana.