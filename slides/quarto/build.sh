#!/bin/sh
# Build the talk.
#   sh build.sh           figures + standalone deck (one self-contained HTML) + preview deck
#   sh build.sh publish   also copy the standalone deck to PhD/Presentations/2026_10_ICTP
# (run through sh: the Nextcloud sync does not keep the executable bit)
# Data for the interactive figures (assets/data) come from julia/export_data.jl; rerun it
# only when the underlying data change (see README.md).
set -e
cd "$(dirname "$0")"
sh collect_figs.sh
# The standalone render removes talk_files/, so it goes first.
quarto render talk.qmd -M embed-resources:true -o talk-standalone.html
quarto render talk.qmd
if [ "$1" = "publish" ]; then
  dest="../../../../Presentations/2026_10_ICTP"
  cp talk-standalone.html "$dest/Absence_QuasiMajos_ICTP.html"
  echo "copied to $dest/Absence_QuasiMajos_ICTP.html"
fi
