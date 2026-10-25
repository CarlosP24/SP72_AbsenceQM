#!/bin/sh
# Static figures of the talk, copied into assets/figs/ (not tracked; rerun after changing
# them): cartoons and panels drawn by slides/make_figs.jl, and the paper's figures from
# plots/figures (PDF → PNG). Needs pdftocairo (poppler).
set -e
cd "$(dirname "$0")"
mkdir -p assets/figs
for f in s08_cartoon_vortex s08_cartoon_fullshell s08_wire_axial s08_pairing_key s09_exp s09_theory \
         s09_cbar s10b_inv_partial s10b_inv_full s16_thumb_partial s16_thumb_skin s16_thumb_full \
         s12_pd_mualpha s04_rs_partial_qmajo s13_rs_full_qmajo; do
  cp "../figs/$f.svg" assets/figs/
done
for f in Fig4 SFig_Conductance SFig_Temperature; do
  pdftocairo -png -r 220 -singlefile "../../plots/figures/$f.pdf" "assets/figs/$f"
done
echo "assets/figs: $(ls assets/figs | wc -l | tr -d ' ') files"
