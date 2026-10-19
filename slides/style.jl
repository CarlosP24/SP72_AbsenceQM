# Shared style for the ICTP talk figures (Trieste, 30 Oct 2026).
# Every figure is rendered at its final size on a 13.33 × 7.5 in slide, so font sizes
# are literal points on the slide. Text in Montserrat (the deck font), math in New
# Computer Modern (as in the paper). Palette as the ICTP poster (plots/poster_figs).

using CairoMakie                          # re-exports colorant"…"

const inch = 72.0                         # pt per inch
const figdir = joinpath(@__DIR__, "figs")

# ---------------------------------------------------------------------------
# Fonts
# ---------------------------------------------------------------------------
const fontdir = expanduser("~/Library/Fonts")
mfont(style) = joinpath(fontdir, "Montserrat-$(style).ttf")
const slide_fonts = (; regular = mfont("Regular"), bold = mfont("Bold"),
    italic = mfont("Italic"), medium = mfont("Medium"), semibold = mfont("SemiBold"),
    bold_italic = mfont("BoldItalic"))
# Bundled math font (New Computer Modern), for math glyphs inside Montserrat text
const mathfont = joinpath(dirname(pathof(Makie.MathTeXEngine)), "..", "assets", "fonts",
    "NewComputerModern", "NewCMMath-Regular.otf")

# ---------------------------------------------------------------------------
# Sizes (pt on the slide)
# ---------------------------------------------------------------------------
const fs_tick  = 14
const fs_label = 16                       # in-panel labels
const fs_axis  = 18                       # axis labels
const fs_title = 18                       # panel titles

const lw_data   = 2.5
const lw_spine  = 1.2
const lw_guide  = 1.2
const lw_wf     = 3.0
const lw_barrier = 3.0

# ---------------------------------------------------------------------------
# Palette: poster regions + template (QUDYMA theme) accents
# ---------------------------------------------------------------------------
const c_topo      = colorant"#C8102E"     # topological (CSIC red)
const c_topo_tint = colorant"#EE9DA9"
const c_skin      = colorant"#007749"     # trivial skin, the protagonist
const c_skin_tint = colorant"#B3D6C8"
const c_ins       = colorant"#BDBDBD"     # insulating (depleted) region
const c_triv      = colorant"#F4F4F4"     # trivial superconducting region
const c_wfL       = colorant"#23427F"     # probe-side (quasi-)MZM, navy
const c_wfR       = colorant"#E07A00"     # interior quasi-MZM, orange
const c_mu        = colorant"#606060"     # chemical potential guide
const c_grey      = colorant"#8C8C8C"
const c_insline   = colorant"#555555"
const c_ink       = colorant"#0D0D0D"     # theme dk1
const c_ink2      = colorant"#404040"     # theme dk2
const c_accent    = colorant"#BF2633"     # theme accent5 (title rule)
const c_blue      = colorant"#6699CC"     # theme accent1
const c_purple    = colorant"#54416B"     # theme accent6

# device colours of the 3D renders (plots/plotters/sketches.jl)
const c_probe = colorant"#B4B4B4"
const c_semi  = colorant"#FBF6CB"
const c_super = colorant"#B8C7F9"

const Δ0 = 0.23                           # meV, parent gap (both wire models)
const cmap = :thermal                     # LDOS / DOS colormap (paper)

# ---------------------------------------------------------------------------
# Theme
# ---------------------------------------------------------------------------
function slide_theme()
    Theme(
        fonts = slide_fonts,
        fontsize = fs_tick,
        textcolor = c_ink,
        backgroundcolor = :white,
        figure_padding = 0,
        Axis = (
            xticklabelsize = fs_tick, yticklabelsize = fs_tick,
            xlabelsize = fs_axis, ylabelsize = fs_axis,
            titlesize = fs_title, titlefont = :medium,
            spinewidth = lw_spine, xtickwidth = lw_spine, ytickwidth = lw_spine,
            xticksize = 5, yticksize = 5,
            xgridvisible = false, ygridvisible = false,
            xticklabelpad = 3, yticklabelpad = 3,
            xlabelpadding = 2, ylabelpadding = 4,
        ),
        Text = (; fontsize = fs_label),
        Lines = (; linewidth = lw_data),
    )
end
set_theme!(slide_theme())

# ---------------------------------------------------------------------------
# Figures with absolutely positioned axes
# ---------------------------------------------------------------------------
# All figures are W × H inches. Axes are placed with `pax`, by their plot area in
# inches from the top-left corner of the figure, so that hiding decorations, or
# rendering only some layers, never moves an axis. Figures that must align on the
# slide (stacked panels, build layers) share their margins.
newfig(W, H; transparent = true) =
    Figure(size = (W * inch, H * inch), backgroundcolor = transparent ? :transparent : :white)

function pax(fig, x, y, w, h; kw...)
    H = fig.scene.viewport[].widths[2] / inch
    bb = BBox(x * inch, (x + w) * inch, (H - y - h) * inch, (H - y) * inch)
    return Axis(fig; bbox = bb, kw...)
end

# Empty axis spanning the whole figure in data units (0..W, 0..H inches, y up)
function canvas(fig)
    W, H = fig.scene.viewport[].widths ./ inch
    ax = Axis(fig; bbox = BBox(0, W * inch, 0, H * inch), backgroundcolor = :transparent)
    hidedecorations!(ax); hidespines!(ax)
    limits!(ax, 0, W, 0, H)
    return ax
end

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------
# SVG (placed in the deck), PDF (vector copy) and a 300 dpi PNG (the deck's
# fallback for viewers without SVG support, and the QA renders).
function export_fig(fig, name)
    mkpath(figdir)
    save(joinpath(figdir, "$(name).svg"), fig; pt_per_unit = 1)
    save(joinpath(figdir, "$(name).pdf"), fig; pt_per_unit = 1)
    save(joinpath(figdir, "$(name).png"), fig; px_per_unit = 300 / 72)
    return name
end

# ---------------------------------------------------------------------------
# Small drawing helpers
# ---------------------------------------------------------------------------
function rounded_rect(x0, y0, w, h, r; n = 12)
    pts = Point2f[]
    for (cx, cy, a0) in ((x0 + w - r, y0 + r, -π/2), (x0 + w - r, y0 + h - r, 0.0),
                         (x0 + r, y0 + h - r, π/2), (x0 + r, y0 + r, π))
        for θ in range(a0, a0 + π/2, length = n)
            push!(pts, Point2f(cx + r * cos(θ), cy + r * sin(θ)))
        end
    end
    return pts
end

# Rounded tag with white bold text; (x, y) is its top-right corner in relative axis
# coordinates. Sized to the text in pixel space.
function tag!(ax, txt, color; x = 0.97, y = 0.94, fontsize = fs_label, padx = 8, pady = 5)
    tw = Makie.text_bb(txt, Makie.to_font(slide_fonts.bold), fontsize).widths[1]
    w, h = tw + 2padx, fontsize + 2pady
    corner = lift(vp -> Point2f(x * vp.widths[1], y * vp.widths[2]), ax.scene.viewport)
    poly!(ax, lift(c -> rounded_rect(c[1] - w, c[2] - h, w, h, 6), corner); space = :pixel,
        color, strokecolor = :white, strokewidth = 1.2)
    text!(ax, lift(c -> c .- Point2f(w / 2, h / 2), corner); space = :pixel, text = txt,
        font = :bold, color = :white, fontsize, align = (:center, :center))
end

# Horizontal measuring bar with end caps (data coordinates)
function mbar!(ax, x0, x1, y; color = :white, linewidth = 2, cap = 0.02)
    lines!(ax, [x0, x1], [y, y]; color, linewidth)
    for x in (x0, x1)
        lines!(ax, [x, x], [y - cap, y + cap]; color, linewidth)
    end
end
