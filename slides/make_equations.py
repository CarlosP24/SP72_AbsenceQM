"""Equations of the ICTP talk, rendered with LaTeX (Computer Modern, as in the earlier
decks) to SVG (placed in the deck), PDF and a 600 dpi PNG fallback.

Each equation is typeset at its final size on the slide (FONT_PT), so it is placed at
its natural size. The LaTeX source of every equation is written to equations/sources.json;
the deck builder copies it into the picture's alt text, so any equation can be retyped
(e.g. with IguanaTex or LaTeXiT) without hunting for it.

Run from anywhere:  python3 slides/make_equations.py
Needs pdflatex and pdftocairo (TeX Live, poppler).
"""
import json
import pathlib
import shutil
import subprocess
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE / "equations"
FONT_PT = 22          # body-math size on the slide
INK = "0D0D0D"        # theme dk1

EQS = {
    # slide 3
    "eq_vzc": r"V_\mathrm{Z} > V_\mathrm{Z}^\mathrm{c} = \sqrt{\Delta_0^2 + \mu_\mathrm{bulk}^2}",
    # slide 4
    "eq_muz": r"\mu(z) = \mu_\mathrm{bulk}\,\bigl(1 - e^{-z/\chi}\bigr)",
    "eq_local": r"V_\mathrm{Z} > \sqrt{\Delta_0^2 + \mu(z)^2}",
    # slide 5
    "eq_chi": r"\chi \gg \frac{\hbar\alpha\,\mu_\mathrm{bulk}}{V_\mathrm{Z}\,\Delta_0}",
    # slide 7
    "eq_flux": r"\Phi = \pi R^2 B, \qquad n = \lfloor \Phi/\Phi_0 \rceil, \qquad \Phi_0 = \frac{h}{2e}",
    # slide 8
    "eq_cdgm_vortex": r"\delta E \simeq \frac{\Delta^2}{2E_F} \sim 10^{-3}\,\Delta",
    "eq_cdgm_fs": r"\delta E \sim \Delta",
    # slide 10
    "eq_jz": r"[H, J_z] = 0, \qquad J_z = -i\partial_\varphi + \tfrac{1}{2}\sigma_z + \tfrac{1}{2}n\,\tau_z",
    "eq_phs": r"\mathcal{P}\,\Psi_{m_J}(E) = \Psi_{-m_J}(-E)",
    "eq_mj0": r"m_J = 0 \;\Rightarrow\; n\ \mathrm{odd}",
    # slide 11
    "eq_bessel": (r"e\phi_g(r, z) = \mu_\mathrm{bulk} \sum_{\nu = 1}^{\infty}"
                  r"\frac{2}{k_\nu J_1(k_\nu)}\, J_0\!\Bigl(k_\nu \frac{r}{R}\Bigr)\, e^{-k_\nu z / k_1 \chi}"),
    # backup B1
    "eq_h_partial": (r"H = \Bigl[\frac{p_z^2}{2m^*} - \mu_\mathrm{bulk} + e\phi_g(z)\Bigr]\tau_z"
                     r" + \alpha\, p_z \sigma_y \tau_z + V_\mathrm{Z}\,\sigma_z + \Sigma_\mathrm{SC}(\omega, V_\mathrm{Z})"),
    "eq_sigma_sc": (r"\Sigma_\mathrm{SC} = \Gamma_\mathrm{NS}\,\frac{\Delta(V_\mathrm{Z})\,\tau_x - \omega}"
                    r"{\sqrt{\Delta(V_\mathrm{Z})^2 - \omega^2}}, \qquad"
                    r" \Delta(V_\mathrm{Z}) = \Delta_0 \sqrt{1 - (V_\mathrm{Z}/V_C)^2}"),
    # backup B2
    "eq_mu_eff": r"\mu(z) \simeq \mu_\mathrm{bulk}\,\bigl(1 - 0.85\, e^{-z/\chi}\bigr)",
}

PREAMBLE = r"""\documentclass[border=1.5pt]{standalone}
\usepackage{amsmath,amssymb}
\usepackage{anyfontsize}
\usepackage{xcolor}
\begin{document}
\fontsize{%(pt)s}{%(lead)s}\selectfont\color[HTML]{%(ink)s}%%
$\displaystyle %(body)s$
\end{document}
"""


def render(name, body, tmp):
    tex = tmp / f"{name}.tex"
    tex.write_text(PREAMBLE % {"pt": FONT_PT, "lead": int(FONT_PT * 1.2), "ink": INK, "body": body})
    subprocess.run(["pdflatex", "-interaction=nonstopmode", "-halt-on-error", tex.name],
                   cwd=tmp, check=True, capture_output=True)
    pdf = tmp / f"{name}.pdf"
    shutil.copy(pdf, OUT / f"{name}.pdf")
    subprocess.run(["pdftocairo", "-svg", str(pdf), str(OUT / f"{name}.svg")], check=True)
    subprocess.run(["pdftocairo", "-png", "-r", "600", "-transp", "-singlefile", str(pdf),
                    str(OUT / name)], check=True)


def main():
    OUT.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory() as d:
        for name, body in EQS.items():
            render(name, body, pathlib.Path(d))
            print("  ", name)
    (OUT / "sources.json").write_text(json.dumps(EQS, indent=1, ensure_ascii=False))


if __name__ == "__main__":
    main()
