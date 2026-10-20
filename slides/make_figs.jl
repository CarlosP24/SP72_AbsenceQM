# Figures for the ICTP talk (Joint ICTP–WE Heraeus College on Advances in Topological
# Quantum Matter, Trieste, 30 Oct 2026). Everything is drawn from the published data
# in data/ (plus data_unpublished/PD_mu_flux/base_fs.jld2, as the poster), from the two
# illustrative intro calculations in slides/data/ (calc_sharp_ldos.jl,
# calc_cdgm_bands.jl), and from the Deng et al. PRL 134, 206302 (2025) data kept in
# PT_Thesis/PT3_CdGM. No result of the paper is recomputed.
#
# Each figure is rendered at its final size on the slide (style.jl). Figures revealed
# step by step on a slide are exported as layers: same canvas, transparent background,
# each holding only its own elements, so the deck stacks them at one position.
#
# Run from anywhere:  julia slides/make_figs.jl [prefix ...]   (no prefix: all figures)
# Output: slides/figs/<name>.{svg,pdf,png}

cd(joinpath(@__DIR__, ".."))
using Pkg
Pkg.activate("plots"; io = devnull)
using CairoMakie, Parameters, JLD2
using Quantica, FullShell
using FunctionZeros, SpecialFunctions, LinearAlgebra, Statistics

include(joinpath(pwd(), "src/utilities.jl"))
include_all("builders")
include(joinpath(pwd(), "src/models/models.jl"))
include(joinpath(@__DIR__, "style.jl"))

const PT3 = joinpath(homedir(), "Library/CloudStorage/Nextcloud-saco.csic.es-CARLOSPAYAHERRERO",
    "PhD/PT_Thesis/PT3_CdGM")

## ===========================================================================
## Data helpers
## ===========================================================================
loadres(path) = JLD2.load(path, "res")

# mirror an ω ≤ 0 grid (last point ω = 0) to ±ω; M has ω along dims = 2
mirror_ω(ω) = vcat(ω, -reverse(ω)[2:end])
mirror_M(M) = cat(M, reverse(M, dims = 2)[:, 2:end], dims = 2)

const VZc = sqrt(2.0^2 + Δ0^2)            # partial shell: V_Z^c = √(μ_bulk² + Δ0²) (meV)
const B1, B2 = 3.0, 1.8                   # V_Z^(1), V_Z^(2) (meV), paper Fig. 1(b, c)
const Φ1, Φ2 = 0.65, 0.88                 # Φ^(1), Φ^(2), paper Fig. 1(f, h)
const μbulkF = 22.8                       # full shell μ_bulk (meV)
const c_crit = colorant"#DE9151"           # V_Z^c / Φ^c guide (theme accent2, the paper's orange)
const cmap_end = (first(to_colormap(cmap)), last(to_colormap(cmap)))

# Φ^c: flux of the m_J = 0 bulk transition at μ_bulk (paper Fig. 1f–h, plot_TT)
const Φc = let r = loadres("data/PD_flux/base_fs.jld2")
    PD, Φs = r.PD, r.system.calc_params.Φrng_PD
    Φs[findfirst(PD[1:end-1] .!= PD[2:end])]
end

# Transitions of a phase-diagram column (μ values where the phase flips)
function pd_transitions(μs, col)
    idx = findall(col[1:end-1] .!= col[2:end])
    return [(μs[i] + μs[i+1]) / 2 for i in idx]
end

# Local chemical potential along the wire, μ(z)/μ_bulk with z in units of χ.
# Partial shell: Eq. (A2). Full shell: Bessel barrier of build_barrier projected on the
# radial density of the m_J = 0, m_r = 1 mode (as the poster, plots/poster_figs/REPORT.md).
μz_partial(z) = 1 - exp(-z)

function μz_full_factory(; Φ = Φ2)
    pw = base_fs.params_wire
    hSM, _, _ = build_cyl(pw)
    H = Matrix(hSM(SA[0.0]; μ = 0, Φ, Z = 0))
    eidx = vcat([[4i + 1, 4i + 2] for i in 0:size(H, 1)÷4-1]...)
    E, V = eigen(Hermitian(H[eidx, eidx]))
    k = findfirst(>(10), E)                        # m_r = 1 band bottom (~21.8 meV)
    rs = [s[2] for s in sites(lattice(hSM))]
    ρ = [abs2(V[2j-1, k]) + abs2(V[2j, k]) for j in eachindex(rs)]
    U = bessel_barrier_kernel(pw.R, 100)
    return z -> 1 - sum(ρ .* [U(z, r, 1.0, 1.0) for r in rs])
end
const μz_full2 = μz_full_factory(; Φ = Φ2)        # Q-MZM case
const μz_full1 = μz_full_factory(; Φ = Φ1)        # MZM case

function z_of_μ(f, y; lo = 0.0, hi = 30.0)
    for _ in 1:80
        mid = (lo + hi) / 2
        f(mid) < y ? (lo = mid) : (hi = mid)
    end
    return (lo + hi) / 2
end

function phase_data()
    res = loadres("data/PD_mu_B/base_partial.jld2")
    cp = res.system.calc_params
    j = argmin(abs.(cp.Brng .- B2))
    μc_partial = maximum(pd_transitions(cp.μrngP, res.PD[:, j])) / 2      # / μ_bulk
    res = loadres("data/PD_mu_flux/base_fs_zoom.jld2")
    cp = res.system.calc_params
    j = argmin(abs.(cp.Φrng_PD .- Φ2))
    μts, μtop = pd_transitions(cp.μrng, res.PD[:, j]) ./ μbulkF
    j1 = argmin(abs.(cp.Φrng_PD .- Φ1))
    μts1 = first(pd_transitions(cp.μrng, res.PD[:, j1])) / μbulkF
    return (;
        μc_partial, μts, μtop, μts1,
        zP_topo_end = z_of_μ(μz_partial, μc_partial),
        zF1_skin_end = z_of_μ(μz_full1, μts1),
        zF_skin_end = z_of_μ(μz_full2, μts),
        zF_topo_end = z_of_μ(μz_full2, μtop),
    )
end
const PH = phase_data()

# Separable Gaussian blur of a grid (σ in cells per dimension; edges clamped)
function gblur(Z, σs...)
    A = Float64.(Z)
    for (dim, σ) in enumerate(σs)
        σ > 0 || continue
        r = ceil(Int, 3σ)
        w = exp.(-((-r:r) .^ 2) ./ (2σ^2))
        w ./= sum(w)
        n = size(A, dim)
        B = similar(A)
        for I in CartesianIndices(A)
            t = Tuple(I)
            B[I] = sum(wk * A[Base.setindex(t, clamp(t[dim] + k, 1, n), dim)...] for (k, wk) in zip(-r:r, w))
        end
        A = B
    end
    return A
end

# Topological region (Z > 0) as vector polygons: level-0 contour of the blurred map
pd_topo!(ax, xs, ys, Z; σ = (4, 1.5)) =
    contourf!(ax, xs, ys, gblur(Z, σ...); levels = [0.0, 2.0], colormap = [c_topo_tint, c_topo_tint])

## ===========================================================================
## Shared pieces
## ===========================================================================
function overlay_axis!(ax)
    hidedecorations!(ax); hidespines!(ax)
    ax.backgroundcolor = :transparent
    return ax
end

function heat!(ax, x, y, M; crange, kw...)
    heatmap!(ax, x, y, M; colormap = cmap, colorrange = crange, highclip = cmap_end[2],
        lowclip = cmap_end[1], nan_color = cmap_end[1], rasterize = 4, kw...)
end

# Legend row of phase colours, drawn on a figure-wide canvas at height y (inches from top)
function phase_legend!(fig, x0, y; items = ((c_ins, "Insulating"), (c_triv, "Trivial"),
        (c_topo_tint, "Topological")), fs = fs_tick, gap = 0.28)
    cv = canvas(fig)
    H = fig.scene.viewport[].widths[2] / inch
    x = x0
    for (c, lab) in items
        poly!(cv, Rect2f(x, H - y - 0.09, 0.18, 0.18); color = c, strokecolor = c_ink, strokewidth = 1)
        text!(cv, x + 0.26, H - y; text = lab, fontsize = fs, align = (:left, :center))
        tw = Makie.text_bb(lab, Makie.to_font(slide_fonts.regular), fs).widths[1] / inch
        x += 0.26 + tw + gap
    end
    return cv
end

# Second x axis on top of `ax` (same limits), for marks like V_Z^(1), Φ^c
function top_marks!(fig, ax, ticks, labels; color = c_ink, fs = fs_label)
    top = Axis(fig; bbox = ax.layoutobservables.suggestedbbox[], xaxisposition = :top,
        backgroundcolor = :transparent, xticks = (ticks, labels), xticklabelsize = fs,
        xticklabelcolor = color, xtickcolor = color, xticksize = 5)
    hideydecorations!(top); hidespines!(top)
    top.xticksmirrored = false
    # the empty top axis has no limits of its own: copy those of `ax` before linking,
    # or the link falls back to its default range (PT3_CdGM flux_axis!)
    lims = ax.limits[]
    lims isa Tuple && !isnothing(lims[1]) && xlims!(top, lims[1]...)
    linkxaxes!(ax, top)
    return top
end

# Label set in the x tick-label band of `ax`, centred at data x (poster inline_xlabel!)
function inline_xlabel!(ax, label, x; fs = fs_axis)
    pos = lift(ax.scene.viewport, ax.finallimits) do vp, lims
        s = ax.xscale[]
        lo, hi = lims.origin[1], lims.origin[1] + lims.widths[1]
        f = (s(x) - s(lo)) / (s(hi) - s(lo))
        Point2f(vp.origin[1] + f * vp.widths[1], vp.origin[2] - 5 - 3 - fs_tick / 2 - 1)
    end
    text!(ax.blockscene, pos; text = label, fontsize = fs, align = (:center, :center))
end

# Ticks in units of χ along z: 0, 2χ, 4χ, …
function zticks(zmax)
    zt = 0:2:floor(Int, zmax)
    return (collect(zt), [n == 0 ? rich("0") : rich("$(n)", rich("𝜒"; font = mathfont)) for n in zt])
end

# Longitudinal cut of the device, aligned with z/χ (paper Fig. 1a, d; poster sketch!)
function cut!(ax, shell::Symbol; zl = (-1.0, 6.0), probe_label = true)
    zmin, zend = zl
    ySM = (0.28, 0.62)
    ymid = sum(ySM) / 2
    band!(ax, [zmin, zmin + 0.25], ySM...; color = c_probe)
    band!(ax, [zmin + 0.25, zend], ySM...; color = c_semi)
    band!(ax, [0, zend], ySM[2], ySM[2] + 0.3; color = c_super)
    shell == :full && band!(ax, [0, zend], ySM[1] - 0.28, ySM[1]; color = c_super)
    probe_label && text!(ax, zmin + 0.05, ySM[2] + 0.04; text = "probe", fontsize = fs_tick,
        align = (:left, :bottom))
    text!(ax, 0.5, ySM[2] + 0.15; text = "SC", fontsize = fs_tick, align = (:left, :center))
    text!(ax, 0.5, ymid; text = "SM", fontsize = fs_tick, align = (:left, :center))
    xB0, xB1 = 0.32zend, 0.62zend
    arrows2d!(ax, [xB0], [ymid], [xB1], [ymid]; argmode = :endpoint, color = :red,
        shaftwidth = 3, tiplength = 12, tipwidth = 12)
    text!(ax, xB1 + 0.1, ymid; text = L"B", color = :red, fontsize = fs_label, align = (:left, :center))
    xlims!(ax, zl...)
    ylims!(ax, 0, 1)
    overlay_axis!(ax)
end

# Band bottom E_c(z)/μ_bulk: 1 − μ(z)/μ_bulk for z ≥ 0, a schematic bump for z < 0 (the
# uncovered, gated section) peaking at ≈1.5 μ_bulk, matched in value and slope at z = 0.
function band_bottom(μz)
    e0 = 1 - μz(0.0)
    s0 = -(μz(1e-3) - μz(0.0)) / 1e-3
    a = 16e0
    c = a + s0 - 3e0
    b = e0 - a - c
    p(t) = a * t^2 + b * t^3 + c * t^4
    return z -> z >= 0 ? 1 - μz(z) : p(z + 1)
end

# Real-space strip for one case (:majo = V_Z^(1) / Φ^(1); :qmajo = V_Z^(2) / Φ^(2)):
# local phases along z, band bottom eφ_g(z) under μ, and the (quasi-)MZM wavefunctions,
# each normalised to its maximum (not to scale with each other, paper ref. [83]).
const wf_scale = 0.9
const yE0, hE = 0.0, 1.35
const y_lbl = 2.20

# bare = true: electrostatics only (insulating end, neutral "Hybrid wire", band bottom, μ, χ),
# without local phases, field label or wavefunctions (slide 4 builds it up in two steps)
# wf = (ΨL, ΨR, χ) replaces the published wavefunctions, corner the field label and
# labR = (z, y) the position of the |Ψ_R|² label
function realspace!(ax, shell::Symbol, case::Symbol; zl = (-1.0, 6.0), fs = fs_tick,
        χbar = (case == :majo && shell == :partial), zlabel = false, minimal = false, bare = false,
        wf = nothing, corner = nothing, labR = nothing)
    zmin, zmax = zl
    lab!(x, txt; color = c_ink, font = :regular) =
        !minimal && text!(ax, x, y_lbl; text = txt, color, font, fontsize = fs, align = (:center, :center))
    vspan!(ax, zmin, 0; color = c_ins)
    if shell == :partial
        name, χ, μz = "base_partial", 200, μz_partial
        if bare
        elseif case == :majo
            vspan!(ax, 0, zmax; color = c_topo_tint)
            lab!(zmax / 2, "Topological")
        else
            z1 = PH.zP_topo_end
            vspan!(ax, 0, z1; color = c_topo_tint)
            vspan!(ax, z1, zmax; color = c_triv)
            lab!(z1 / 2, "Topological"); lab!((z1 + zmax) / 2, "Trivial")
        end
        plab = case == :majo ? L"V_\mathrm{Z} = V_\mathrm{Z}^{(1)}" : L"V_\mathrm{Z} = V_\mathrm{Z}^{(2)}"
    else
        name, χ = "base_fs", 1000
        μz = case == :majo ? μz_full1 : μz_full2
        if bare
        elseif case == :majo
            μz, z1 = μz_full1, PH.zF1_skin_end
            vspan!(ax, 0, z1; color = c_skin_tint)
            vspan!(ax, z1, zmax; color = c_topo_tint)
            lab!(z1 / 2, "Trivial skin"; color = c_skin, font = :bold)
            lab!((z1 + zmax) / 2, "Topological")
        else
            μz, z1, z2 = μz_full2, PH.zF_skin_end, PH.zF_topo_end
            vspan!(ax, 0, z1; color = c_skin_tint)
            vspan!(ax, z1, z2; color = c_topo_tint)
            vspan!(ax, z2, zmax; color = c_triv)
            lab!(z1 / 2, "Trivial skin"; color = c_skin, font = :bold)
            lab!((z1 + z2) / 2, "Topological"); lab!((z2 + zmax) / 2, "Trivial")
        end
        bare || vlines!(ax, [0, PH.zF1_skin_end * (case == :majo) + PH.zF_skin_end * (case != :majo)];
            color = c_skin, linewidth = lw_spine)
        plab = case == :majo ? L"\Phi = \Phi^{(1)}" : L"\Phi = \Phi^{(2)}"
    end
    if bare
        vspan!(ax, 0, zmax; color = :white)
        lab!(zmax / 2, "Hybrid wire")
    end
    isnothing(corner) || (plab = corner)
    minimal || bare || text!(ax, zmax - 0.08, yE0 + hE + 0.08; text = plab, fontsize = fs + 2, align = (:right, :bottom))

    Ec = band_bottom(μz)
    zs = range(zmin, zmax, length = 800)
    # "Ins." under the top of the barrier bump, clear of its steep flanks
    zpk = argmax(Ec, range(zmin, 0, length = 200))
    minimal || text!(ax, zpk, 0.05; text = "Ins.", rotation = π/2, fontsize = fs - 1,
        align = (:left, :center))
    hlines!(ax, yE0 + hE; color = c_mu, linestyle = :dash, linewidth = 2)
    minimal || text!(ax, zmax - 0.08, yE0 + hE - 0.03; text = L"\mu", color = c_mu, fontsize = fs + 2,
        align = (:right, :top))
    lines!(ax, zs, yE0 .+ hE .* Ec.(zs); color = :black, linewidth = minimal ? 2 : lw_barrier)
    case == :majo && !minimal && text!(ax, shell == :full ? 0.55 : 0.2, yE0 + hE + 0.05;
        text = L"e\phi_g(z)", fontsize = fs + 1, align = (:left, :bottom))

    if χbar && !minimal                           # decay length of the barrier
        yχ = shell == :full ? yE0 + hE * Ec(1.0) : 2.17
        x1 = shell == :full ? 1.0 : 1.0
        lines!(ax, [0, x1], [yχ, yχ]; color = :black, linewidth = 2.5)
        for x in (0, x1)
            lines!(ax, [x, x], [yχ - 0.08, yχ + 0.08]; color = :black, linewidth = 2.5)
        end
        text!(ax, x1 + 0.1, yχ; text = L"\chi", fontsize = fs + 4, align = (:left, :center))
    end

    if isnothing(wf)
        Ψs = loadres("data/wfs/$(name).jld2").Psis
        ΨL, ΨR = Ψs[case == :majo ? "Majo" : "QMajo"]
    else
        ΨL, ΨR, χ = wf
    end
    bare && (ΨL = ΨR = fill(NaN, length(ΨL)))      # no wavefunctions in the bare strip
    z = (0:length(ΨL)-1) .* 5 ./ χ
    keep = z .<= zmax
    case == :qmajo && lines!(ax, z[keep], wf_scale .* ΨR[keep] ./ maximum(ΨR); color = c_wfR, linewidth = lw_wf)
    lines!(ax, z[keep], wf_scale .* ΨL[keep] ./ maximum(ΨL); color = c_wfL, linewidth = lw_wf)
    zL, zR = z[argmax(ΨL)], z[argmax(ΨR)]
    labL = L"|\Psi_\mathrm{L}|^2"
    if minimal || bare
    elseif shell == :partial
        text!(ax, zL + 0.45, 0.98; text = labL, color = c_wfL, fontsize = fs + 2, align = (:left, :center))
        posR = isnothing(labR) ? (zR + 0.6, 0.78wf_scale) : labR
        case == :qmajo && text!(ax, posR...; text = L"|\Psi_\mathrm{R}|^2", color = c_wfR, fontsize = fs + 2, align = (:left, :center))
    else
        text!(ax, zL - 0.25, 0.75wf_scale; text = labL, color = c_wfL, fontsize = fs + 2, align = (:right, :center))
        case == :qmajo && text!(ax, zR - 1.1, 0.80wf_scale; text = L"|\Psi_\mathrm{R}|^2", color = c_wfR, fontsize = fs + 2, align = (:right, :center))
    end
    xlims!(ax, zl...)
    ylims!(ax, -0.05, 2.45)
    ax.xticks = zticks(zmax)
    hideydecorations!(ax)
    zlabel && inline_xlabel!(ax, L"z", 2 * floor(Int, zmax / 2) - 1)   # between the last two ticks
    return ax
end

## ===========================================================================
## Slides 3–6: partial shell
## ===========================================================================
# Phase diagram (V_Z, μ), μ/μ_bulk ∈ μlimsP; layers :base, :mzm, :qmzm (μ(z) paths)
const μlimsP = (-0.22, 1.15)
const PDP = (W = 5.0, H = 3.1, x = 0.85, y = 0.42, w = 4.0, h = 2.0)

function path_ticks!(ax, x, μz; Y = identity, labels = true, side = -1, skip = (3,), dx = 0.035)
    for n in 1:3
        y = Y(μz(n))
        lines!(ax, [x - dx, x + dx], [y, y]; color = c_ink, linewidth = 2)
        (labels && !(n in skip)) || continue
        text!(ax, x + side * 2dx, y; text = n == 1 ? L"\chi" : L"%$(n)\chi",
            fontsize = fs_tick, align = (side < 0 ? :right : :left, :center))
    end
end

function fig_pd_partial(layer::Symbol)
    fig = newfig(PDP.W, PDP.H)
    ax = pax(fig, PDP.x, PDP.y, PDP.w, PDP.h)
    xlims!(ax, 0, 2); ylims!(ax, μlimsP...)
    if layer == :base
        res = loadres("data/PD_mu_B/base_partial.jld2")
        cp = res.system.calc_params
        x = cp.Brng ./ VZc
        y = cp.μrngP ./ 2
        xi, yi = findall(x .<= 2.3), findall(-0.5 .<= y .<= 1.5)
        Z = replace(res.PD'[xi, yi], NaN => -1)
        ax.backgroundcolor = c_triv
        pd_topo!(ax, x[xi], y[yi], Z; σ = (5, 1.5))
        hspan!(ax, μlimsP[1], 0; color = c_ins)
        hlines!(ax, 1; color = c_mu, linestyle = :dash, linewidth = lw_guide)
        vlines!(ax, 1; color = c_crit, linestyle = :dash, linewidth = 2)
        ax.xticks = ([0, 1, 2], ["0", "1", "2"])
        ax.yticks = ([0, 1], [L"0", L"\mu_\mathrm{bulk}"])
        ax.xlabel = L"V_\mathrm{Z}/V_\mathrm{Z}^\mathrm{c}"
        ax.ylabel = L"\mu"
        ax.ylabelpadding = -4
        phase_legend!(fig, PDP.x, 0.17)
    else
        overlay_axis!(ax)
        x = (layer == :mzm ? B1 : B2) / VZc
        μc = PH.μc_partial
        segs = layer == :mzm ? [(μlimsP[1], 0, c_insline), (0, 1, c_topo)] :
                               [(μlimsP[1], 0, c_insline), (0, μc, c_topo), (μc, 1, c_ink)]
        for (y0, y1, c) in segs
            lines!(ax, [x, x], [y0, y1]; color = c, linewidth = 4.5, linecap = :butt)
        end
        scatter!(ax, Point2f(x, 1.0); marker = :utriangle, markersize = 20,
            color = last(segs)[3], strokecolor = :white, strokewidth = 1)
        path_ticks!(ax, x, μz_partial; labels = layer == :qmzm)
        # field of the path, in the insulating band
        text!(ax, x + (layer == :mzm ? 0.06 : -0.06), -0.11;
            text = layer == :mzm ? L"V_\mathrm{Z}^{(1)}" : L"V_\mathrm{Z}^{(2)}",
            fontsize = fs_label, align = (layer == :mzm ? :left : :right, :center))
        text!(ax, x, 0.03; text = layer == :mzm ? "MZM" : "Q-MZM", fontsize = fs_tick,
            font = :semibold, rotation = π/2, align = (:left, :bottom), offset = (-7, 0))
        layer == :qmzm && text!(ax, 0.04, 0.97; text = rich(rich("μ(z)"; font = mathfont), " along\nthe wire"),
            color = c_insline, fontsize = fs_tick, align = (:left, :top))
    end
    return fig
end

# End LDOS vs V_Z (ω/Δ0), partial shell: :sharp (slides/data, χ = 1 nm, illustrative) or
# :smooth (data/LDOSvB/base_partial, χ = 200 nm, published data)
const LDV = (W = 5.0, H = 2.45, x = 0.85, y = 0.08, w = 4.0, h = 1.65)
const ldos_vB_crange = (0.0, 0.012)

function ldos_vB_data(which)
    if which == :sharp
        d = JLD2.load("slides/data/LDOSvB_partial_sharp.jld2")
        B, ω, M = d["Brng"], real.(d["ωrng"]), d["LDOS"]
    else
        res = loadres("data/LDOSvB/base_partial.jld2")
        cp = res.system.calc_params
        B, ω, M = collect(cp.Brng), real.(collect(cp.ωrng)), res.LDOS
    end
    return B ./ VZc, mirror_ω(ω) ./ Δ0, mirror_M(M)
end

function fig_ldos_vB(which::Symbol)
    fig = newfig(LDV.W, LDV.H)
    ax = pax(fig, LDV.x, LDV.y, LDV.w, LDV.h)
    x, ω, M = ldos_vB_data(which)
    heat!(ax, x, ω, M; crange = ldos_vB_crange)
    vlines!(ax, 1; color = c_crit, linestyle = :dash, linewidth = 2)
    xlims!(ax, 0, 2); ylims!(ax, -1.1, 1.1)
    ax.xticks = ([0, 1, 2], ["0", "1", "2"])
    ax.yticks = ([-1, 0, 1], ["−1", "0", "1"])
    ax.ylabel = L"\omega/\Delta_0"
    ax.ylabelpadding = 2
    ax.xlabel = L"V_\mathrm{Z}/V_\mathrm{Z}^\mathrm{c}"
    title = which == :sharp ? "End LDOS · sharp end" : "End LDOS · smooth end, χ = 200 nm"
    text!(ax, 0.98, 0.04; space = :relative, text = title, color = :white, fontsize = fs_tick,
        font = :medium, align = (:right, :bottom))
    mbar!(ax, 1.0, 1.98, 0.22; cap = 0.07)
    text!(ax, 1.49, 0.30; text = "MZM", color = :white, fontsize = fs_tick, font = :semibold, align = (:center, :bottom))
    if which == :smooth
        mbar!(ax, 0.62, 1.0, -0.22; cap = 0.07)
        text!(ax, 0.81, -0.30; text = "Q-MZM", color = :white, fontsize = fs_tick, font = :semibold, align = (:center, :top))
    end
    return fig
end

# Real-space strips and the longitudinal cut (slides 4, 5, 13)
const RSP = (W = 6.3, H = 1.80, x = 0.10, y = 0.06, w = 5.85, h = 1.30)
function fig_rs(shell, case; zl = (-1.0, 6.0), zlabel = true, bare = false)
    fig = newfig(RSP.W, RSP.H; transparent = false)
    ax = pax(fig, RSP.x, RSP.y, RSP.w, RSP.h)
    realspace!(ax, shell, case; zl, zlabel, bare)
    return fig
end
function fig_cut(shell; zl = (-1.0, 6.0))
    H = 0.75
    fig = newfig(RSP.W, H)
    ax = pax(fig, RSP.x, 0.0, RSP.w, H)
    cut!(ax, shell; zl, probe_label = false)
    # "probe" on the figure canvas, at the probe's left edge unless it would run into the
    # shell (z = 0): the full shell's longer z range leaves a shorter bare section
    ipu = RSP.w / (zl[2] - zl[1])                                   # inches per unit of z/χ
    wtxt = Makie.text_bb("probe", Makie.to_font(slide_fonts.regular), fs_tick).widths[1] / inch
    x = min(RSP.x + 0.05ipu, RSP.x - zl[1] * ipu - 0.07 - wtxt)
    text!(canvas(fig), x, 0.66H; text = "probe", fontsize = fs_tick, align = (:left, :bottom))
    return fig
end

# Slide 5, one row per end: the quasi-MZM pair at V_Z^(2) and the DOS vs V_Z where μ(z)
# varies, for the paper's smooth end (χ = 200 nm, published data/wfs and data/DOS, paper
# Fig. 1c) and a sharper one (χ = 50 nm, illustrative: slides/calc_qmzm_wfs.jl and
# slides/calc_qmzm_dos.jl), where the pair overlaps and splits
function fig_rs_chi(which::Symbol)
    fig = newfig(RSP.W, RSP.H; transparent = false)
    ax = pax(fig, RSP.x, RSP.y, RSP.w, RSP.h)
    if which == :smooth
        realspace!(ax, :partial, :qmajo; zlabel = true, corner = L"\chi = 200\ \mathrm{nm}")
    else
        d = JLD2.load("slides/data/wfs_partial_chis.jld2")
        i = findfirst(==(50), d["χs"])
        realspace!(ax, :partial, :qmajo; zlabel = true, corner = L"\chi = 50\ \mathrm{nm}",
            wf = (d["ΨL"][i], d["ΨR"][i], 50), labR = (4.55, 1.03))
    end
    return fig
end

# DOS vs V_Z where μ(z) varies (paper Fig. 1c), partial shell, χ = 200 nm
const DSP = (W = 5.0, H = 3.15, x = 0.85, y = 0.40, w = 4.0, h = 2.0)
function fig_dos_partial()
    fig = newfig(DSP.W, DSP.H)
    ax = pax(fig, DSP.x, DSP.y, DSP.w, DSP.h)
    res = loadres("data/DOS/base_partial.jld2")
    cp = res.system.calc_params
    x = collect(cp.Brng) ./ VZc
    ω = mirror_ω(real.(collect(cp.ωrng))) ./ Δ0
    heat!(ax, x, ω, mirror_M(res.DOS); crange = (0, 0.4))
    vlines!(ax, 1; color = c_crit, linestyle = :dash, linewidth = 2)
    xlims!(ax, 0, 2); ylims!(ax, -1.1, 1.1)
    ax.xticks = ([0, 1, 2], ["0", "1", "2"])
    ax.yticks = ([-1, 0, 1], ["−1", "0", "1"])
    ax.xlabel = L"V_\mathrm{Z}/V_\mathrm{Z}^\mathrm{c}"
    ax.ylabel = L"\omega/\Delta_0"
    ax.ylabelpadding = 2
    text!(ax, 0.98, 0.04; space = :relative, text = "DOS where μ(z) varies", color = :white,
        fontsize = fs_tick, font = :medium, align = (:right, :bottom))
    mbar!(ax, 1.0, 1.98, 0.17; cap = 0.07)
    text!(ax, 1.49, 0.25; text = "MZM", color = :white, fontsize = fs_tick, font = :semibold, align = (:center, :bottom))
    mbar!(ax, 0.66, 1.0, -0.17; cap = 0.07)
    text!(ax, 0.83, -0.25; text = "Q-MZM", color = :white, fontsize = fs_tick, font = :semibold, align = (:center, :top))
    top_marks!(fig, ax, [B2 / VZc, B1 / VZc], [L"V_\mathrm{Z}^{(2)}", L"V_\mathrm{Z}^{(1)}"])
    return fig
end

# The slide-5 rows: same DOS where μ(z) varies, zoomed to the subgap states. Each map has its
# own colour range: at χ = 50 nm the NDOS sites sample a 4× shorter region and the subgap
# peaks are twice as high, so its range is doubled to keep the same contrast
const DSR = (W = 5.0, H = 2.14, x = 0.85, y = 0.40, w = 4.0, h = 1.30)
function fig_dos_row(which::Symbol)
    fig = newfig(DSR.W, DSR.H)
    ax = pax(fig, DSR.x, DSR.y, DSR.w, DSR.h)
    if which == :smooth
        res = loadres("data/DOS/base_partial.jld2")
        cp = res.system.calc_params
        B, ω, M, cmax = collect(cp.Brng), real.(collect(cp.ωrng)), res.DOS, 0.4
    else
        d = JLD2.load("slides/data/DOSvB_partial_chi50.jld2")
        B, ω, M, cmax = d["Brng"], real.(d["ωrng"]), d["DOS"], 0.8
    end
    heat!(ax, B ./ VZc, mirror_ω(ω) ./ Δ0, mirror_M(M); crange = (0, cmax))
    vlines!(ax, 1; color = c_crit, linestyle = :dash, linewidth = 2)
    xlims!(ax, 0, 2); ylims!(ax, -0.5, 0.5)
    ax.xticks = ([0, 1, 2], ["0", "1", "2"])
    ax.yticks = ([-0.5, 0, 0.5], ["−0.5", "0", "0.5"])
    ax.ylabel = L"\omega/\Delta_0"
    ax.ylabelpadding = 2
    inline_xlabel!(ax, L"V_\mathrm{Z}/V_\mathrm{Z}^\mathrm{c}", 1.5)
    text!(ax, 0.99, 0.04; space = :relative, text = "DOS where μ(z) varies", color = :white,
        fontsize = fs_tick - 2, font = :medium, align = (:right, :bottom))
    text!(ax, 1.5, 0.08; text = "MZM", color = :white, fontsize = fs_tick, font = :semibold, align = (:center, :bottom))
    # in the dark gap left of where the pair reaches zero energy
    which == :smooth ?
        text!(ax, 0.69, 0; text = "Q-MZM", color = :white, fontsize = fs_tick, font = :semibold, align = (:right, :center)) :
        text!(ax, 0.72, 0; text = "split Q-MZMs", color = :white, fontsize = fs_tick, font = :semibold, align = (:right, :center))
    top_marks!(fig, ax, [B2 / VZc], [L"V_\mathrm{Z}^{(2)}"])
    return fig
end

## ===========================================================================
## End LDOS vs (χ, ω): paper Fig. 2 (and Fig. 3 with "_weak")
## ===========================================================================
function load_ldos(name, key)
    res = loadres("data/LDOS/$(name).jld2")
    @unpack χrng, ωrng = res.system.calc_params
    return collect(χrng), mirror_ω(real.(collect(ωrng))) ./ Δ0, mirror_M(res.LDOS[key])
end
# colour range per row as in the paper: partial 0.1, full 0.01
ldos_crange(name) = startswith(name, "base_partial") ? (0, 1e-1) : (0, 1e-2)

function ldos_chi!(ax, name, key; ωmax = 0.2)
    χ, ω, M = load_ldos(name, key)
    heat!(ax, χ, ω, M; crange = ldos_crange(name))
    ax.xscale = log10
    xlims!(ax, 1, maximum(χ)); ylims!(ax, -ωmax, ωmax)
    ax.xticks = ([1, 10, 100, 1000], ["1", "10", "100", "1000"])
    ax.yticks = ([-0.2, 0, 0.2], ["−0.2", "0", "0.2"])
    return ax
end

# χ beyond which the end-LDOS signal stays below `frac` of its maximum (poster χ_vanish)
function χ_vanish(name, key; frac = 0.01)
    χ, _, M = load_ldos(name, key)
    pk = vec(maximum(M, dims = 2))
    return χ[findlast(pk .>= frac * maximum(pk)) + 1]
end

function colorbar_axis!(fig, x, y, w, h; label = "LDOS (arb. u.)", fs = fs_tick)
    ax = pax(fig, x, y, w, h; yaxisposition = :right, yticks = ([0, 1], ["0", "1"]),
        ylabel = label, ylabelsize = fs, yticklabelsize = fs, ylabelpadding = -10)
    limits!(ax, 0, 1, 0, 1)
    hidexdecorations!(ax)
    heatmap!(ax, [0, 1], range(0, 1, 200), repeat(collect(range(0, 1, 200))', 2); colormap = cmap,
        rasterize = 4)
    return ax
end

# Slide 6: partial-shell LDOS vs χ, MZM (top) and Q-MZM (bottom); layers :majo, :qmajo, :tag
const LCP = (W = 5.6, H = 4.85, x = 0.85, w = 4.05, h = 1.55, y1 = 0.36, y2 = 2.62)
function fig_ldos_chi_partial(layer::Symbol)
    fig = newfig(LCP.W, LCP.H)
    if layer in (:majo, :qmajo)
        y = layer == :majo ? LCP.y1 : LCP.y2
        ax = pax(fig, LCP.x, y, LCP.w, LCP.h)
        ldos_chi!(ax, "base_partial_szoom", layer == :majo ? "Majo" : "QMajo")
        ax.ylabel = L"\omega/\Delta_0"; ax.ylabelpadding = 2
        layer == :qmajo && (ax.xlabel = L"\chi\ \mathrm{(nm)}"; ax.xlabelpadding = 0)
        lab = layer == :majo ? L"V_\mathrm{Z} = V_\mathrm{Z}^{(1)}" : L"V_\mathrm{Z} = V_\mathrm{Z}^{(2)}"
        text!(ax, 0.97, 0.06; space = :relative, text = lab, color = :white, fontsize = fs_label, align = (:right, :bottom))
        cv = canvas(fig)
        text!(cv, LCP.x + LCP.w / 2, LCP.H - y + 0.04; text = layer == :majo ? "True MZM" : "Quasi-MZM",
            fontsize = fs_title, font = :semibold, align = (:center, :bottom))
        colorbar_axis!(fig, LCP.x + LCP.w + 0.12, y, 0.14, LCP.h)
    else
        ax = pax(fig, LCP.x, LCP.y2, LCP.w, LCP.h)
        overlay_axis!(ax)
        tag!(ax, "False positive", c_topo; y = 0.94)
    end
    return fig
end

## ===========================================================================
## Slide 13 (no false positives): 2 × 2 grid, layers :partial, :fullM, :fullQ, :ann, :tags
## ===========================================================================
const GRD = (W = 11.5, H = 4.75, xr = 0.0, x1 = 2.35, x2 = 6.75, w = 4.0, h = 1.60,
    y1 = 0.40, y2 = 2.38, cb = 10.92)
function device_icon!(fig, shell, x, y, w)
    img = CairoMakie.FileIO.load(shell == :partial ? "plots/sketches/partial-shell.png" : "plots/sketches/full-shell.png")
    h = w * size(img, 1) / size(img, 2)
    ax = pax(fig, x, y, w, h; aspect = DataAspect(), backgroundcolor = :transparent)
    image!(ax, reverse(img, dims = 1)')
    hidedecorations!(ax); hidespines!(ax)
    return h
end

function fig_ldos_grid(layer::Symbol)
    fig = newfig(GRD.W, GRD.H)
    rowlabel!(r, shell, title) = begin
        y = r == 1 ? GRD.y1 : GRD.y2
        h = device_icon!(fig, shell, 0.15, y + 0.05, 1.25)
        cv = canvas(fig)
        text!(cv, 0.78, GRD.H - (y + 0.12 + h); text = title, font = :bold, fontsize = fs_label,
            align = (:center, :top))
    end
    panel(r, c) = begin
        ax = pax(fig, c == 1 ? GRD.x1 : GRD.x2, r == 1 ? GRD.y1 : GRD.y2, GRD.w, GRD.h)
        name = r == 1 ? "base_partial_szoom" : "base_fs_szoom"
        ldos_chi!(ax, name, c == 1 ? "Majo" : "QMajo")
        c == 1 ? (ax.ylabel = L"\omega/\Delta_0"; ax.ylabelpadding = 2) : hideydecorations!(ax; ticks = false)
        r == 2 && (ax.xlabel = L"\chi\ \mathrm{(nm)}"; ax.xlabelpadding = 0)
        lab = r == 1 ? (c == 1 ? L"V_\mathrm{Z} = V_\mathrm{Z}^{(1)}" : L"V_\mathrm{Z} = V_\mathrm{Z}^{(2)}") :
                       (c == 1 ? L"\Phi = \Phi^{(1)}" : L"\Phi = \Phi^{(2)}")
        text!(ax, 0.97, 0.06; space = :relative, text = lab, color = :white, fontsize = fs_label, align = (:right, :bottom))
        ax
    end
    if layer == :partial
        cv = canvas(fig)
        for (c, t) in ((1, "True MZM"), (2, "Quasi-MZM"))
            text!(cv, (c == 1 ? GRD.x1 : GRD.x2) + GRD.w / 2, GRD.H - 0.17; text = t,
                font = :semibold, fontsize = fs_title, align = (:center, :center))
        end
        panel(1, 1); panel(1, 2)
        rowlabel!(1, :partial, "Partial shell")
        colorbar_axis!(fig, GRD.cb, GRD.y1, 0.14, GRD.h)
    elseif layer == :fullM
        # the lower-row colorbar is its own picture (s14_grid_cbarF), moved by Morph on the slide
        panel(2, 1)
        rowlabel!(2, :full, "Full shell")
    elseif layer == :fullQ
        panel(2, 2)
    elseif layer == :ann
        χs = max(χ_vanish("base_fs_szoom", "Majo"), χ_vanish("base_fs_szoom", "QMajo"))
        for c in 1:2
            ax = pax(fig, c == 1 ? GRD.x1 : GRD.x2, GRD.y2, GRD.w, GRD.h)
            overlay_axis!(ax)
            xlims!(ax, 1, 10^3.5); ylims!(ax, -0.2, 0.2)
            ax.xscale = log10
            vlines!(ax, χs; color = :white, linestyle = :dash, linewidth = 2)
            if c == 1
                text!(ax, χs / 1.3, 0.185; text = "sharp end:\nprobe works", color = :white,
                    fontsize = fs_tick, align = (:right, :top), justification = :right)
                text!(ax, χs * 1.3, 0.185; text = "smooth end:\ntrivial skin hides all", color = :white,
                    fontsize = fs_tick, align = (:left, :top), justification = :left)
            end
        end
    elseif layer in (:tagP, :tagF)
        for (r, t, c) in ((1, "False positive", c_topo), (2, "No false positive", c_skin))
            (r == 1) == (layer == :tagP) || continue
            ax = pax(fig, GRD.x2, r == 1 ? GRD.y1 : GRD.y2, GRD.w, GRD.h)
            overlay_axis!(ax)
            tag!(ax, t, c; y = 0.94)
        end
    end
    return fig
end

# Lower-row colorbar alone: same height as the grid canvas, bar at the row's y and 0.02 in
# from its left edge, so it can sit next to the true-MZM panel or at GRD.cb
const GRD_CB = (W = 0.62, x = 0.02)
function fig_ldos_grid_cbar()
    fig = newfig(GRD_CB.W, GRD.H)
    colorbar_axis!(fig, GRD_CB.x, GRD.y2, 0.14, GRD.h)
    return fig
end

## ===========================================================================
## Slide 14: short-range disorder (paper Fig. 3), layers :partial, :full
## ===========================================================================
const DIS = (W = 6.6, H = 4.6, x1 = 1.32, x2 = 3.67, w = 2.25, h = 1.55, y1 = 0.40, y2 = 2.30, cb = 6.04)
function fig_disorder(layer::Symbol)
    fig = newfig(DIS.W, DIS.H)
    r = layer == :partial ? 1 : 2
    y = r == 1 ? DIS.y1 : DIS.y2
    name = r == 1 ? "base_partial_szoom_weak" : "base_fs_szoom_weak"
    cv = canvas(fig)
    if r == 1
        for (c, t) in ((1, "True MZM"), (2, "Quasi-MZM"))
            text!(cv, (c == 1 ? DIS.x1 : DIS.x2) + DIS.w / 2, DIS.H - 0.17; text = t,
                font = :semibold, fontsize = fs_label, align = (:center, :center))
        end
    end
    text!(cv, 0.02, DIS.H - y - DIS.h / 2; text = r == 1 ? "Partial" : "Full", font = :bold,
        fontsize = fs_label, rotation = π/2, align = (:center, :top))
    for c in 1:2
        ax = pax(fig, c == 1 ? DIS.x1 : DIS.x2, y, DIS.w, DIS.h)
        ldos_chi!(ax, name, c == 1 ? "Majo" : "QMajo")
        c == 1 ? (ax.ylabel = L"\omega/\Delta_0"; ax.ylabelpadding = 2) : hideydecorations!(ax; ticks = false)
        r == 2 && (ax.xlabel = L"\chi\ \mathrm{(nm)}"; ax.xlabelpadding = 0)
    end
    colorbar_axis!(fig, DIS.cb, y, 0.13, DIS.h)
    return fig
end

## ===========================================================================
## Slides 7–9: full-shell basics
## ===========================================================================
# DOS vs Φ, lobes 0–2 (paper Fig. 1g data): all m_J (:total) and the m_J = 0 sector,
# which exists only in odd lobes (:mj0); χ = 1 µm, DOS where μ(z) varies
const LOB = (W = 6.3, H = 4.85, x = 0.85, w = 5.15, h = 1.60, y1 = 0.40, y2 = 2.50)
mJ_rich(rest) = rich(rich("m"; font = :italic), subscript("J"; font = :italic), rest)
function fig_dos_lobes(layer::Symbol; crange_mj0 = (0, 0.8))
    fig = newfig(LOB.W, LOB.H)
    res = loadres("data/DOS/base_fs_Zs.jld2")
    cp = res.system.calc_params
    Φ = collect(cp.Φrng_DOS)
    ω = mirror_ω(real.(collect(cp.ωrng))) ./ Δ0
    y = layer == :total ? LOB.y1 : LOB.y2
    ax = pax(fig, LOB.x, y, LOB.w, LOB.h)
    if layer == :total
        heat!(ax, Φ, ω, mirror_M(sum(values(res.DOS))); crange = (0, 4))
        txt = rich("All ", mJ_rich(" sectors"))
    else
        M = mirror_M(res.DOS[0])
        odd = 0.5 .<= Φ .< 1.5
        M[.!odd, :] .= NaN
        heat!(ax, Φ, ω, M; crange = crange_mj0, nan_color = :transparent)
        ax.backgroundcolor = c_triv
        for xx in (0.25, 2.0)
            text!(ax, xx, 0.0; text = rich("no ", mJ_rich(" = 0\nsector")), color = c_ink2,
                fontsize = fs_tick, align = (:center, :center), justification = :center)
        end
        txt = mJ_rich(" = 0 only")
        ax.xlabel = L"\Phi/\Phi_0"; ax.xlabelpadding = 0
    end
    text!(ax, 0.985, 0.04; space = :relative, text = txt, color = layer == :total ? :white : c_ink,
        fontsize = fs_tick, font = :semibold, align = (:right, :bottom))
    vlines!(ax, [0.5, 1.5]; color = (:white, 0.6), linestyle = :dot, linewidth = 1.5)
    xlims!(ax, 0, 2.5)
    ax.xticks = ([0, 0.5, 1, 1.5, 2, 2.5], ["0", "0.5", "1", "1.5", "2", "2.5"])
    if layer == :total
        ylims!(ax, -1.1, 1.1)
        ax.yticks = ([-1, 0, 1], ["−1", "0", "1"])
    else
        # zoom on the zero mode. Tick-label space of the top panel ("−1"), so that both
        # ω/Δ0 labels line up on the slide; "−0.2" only reaches into it at the axis ends.
        ylims!(ax, -0.2, 0.2)
        ax.yticks = ([-0.2, 0, 0.2], ["−0.2", "0", "0.2"])
        ax.yticklabelspace = Float64(Makie.text_bb("−1", Makie.to_font(slide_fonts.regular), fs_tick).widths[1])
    end
    ax.ylabel = L"\omega/\Delta_0"; ax.ylabelpadding = 2
    # fluxoid number of each Little–Parks lobe, on top
    layer == :total && top_marks!(fig, ax, [0.25, 1.0, 2.0], ["n = 0", "n = 1", "n = 2"]; fs = fs_tick)
    return fig
end

## ===========================================================================
## Slides 10–12: full shell with smooth confinement
## ===========================================================================
# Schematic μ axis of the full-shell phase diagram (poster μaxis): 0 → μ^ts compressed
# into the lower half, the narrow μ^ts → μ_bulk window stretched over the upper half.
function μaxis(μts; w = 0.005)
    a, b = 0.5 / μts, 0.5 / (1 - μts)
    raw(μ) = a * μ + (b - a) * w * log1p(exp((μ - μts) / w))
    r0, r1 = raw(0.0), raw(1.0)
    Y(μ) = (raw(μ) - r0) / (r1 - r0)
    function Yinv(y)
        lo, hi = -2.0, 3.0
        for _ in 1:60
            mid = (lo + hi) / 2
            Y(mid) < y ? (lo = mid) : (hi = mid)
        end
        return (lo + hi) / 2
    end
    return Y, Yinv
end
const Yμ, Yμinv = μaxis(PH.μts)
const μlimsF = (-0.2, 1.1)
const PDF = (W = 5.4, H = 4.05, x = 0.95, y = 0.42, w = 4.25, h = 2.85)

function fig_pd_full(layer::Symbol)
    fig = newfig(PDF.W, PDF.H)
    ax = pax(fig, PDF.x, PDF.y, PDF.w, PDF.h)
    xlims!(ax, 0.5, 1.5); ylims!(ax, μlimsF...)
    yts, ytop = Yμ(PH.μts), Yμ(PH.μtop)
    if layer == :base
        r = loadres("data/PD_mu_flux/base_fs_zoom.jld2")
        Φs, μz_, PDz = r.system.calc_params.Φrng_PD, r.system.calc_params.μrng, r.PD
        r = loadres("data_unpublished/PD_mu_flux/base_fs.jld2")
        μc_, PDc = r.system.calc_params.μrng, r.PD
        ys = range(0, μlimsF[2], length = 1200)
        function lerp(v, col, x)
            i = clamp(searchsortedlast(v, x), 1, length(v) - 1)
            t = clamp((x - v[i]) / (v[i+1] - v[i]), 0, 1)
            return (1 - t) * col[i] + t * col[i+1]
        end
        M = [begin
                μ = μbulkF * Yμinv(y)
                first(μz_) <= μ <= last(μz_) ? lerp(μz_, view(PDz, :, j), μ) : lerp(μc_, view(PDc, :, j), μ)
             end for j in eachindex(Φs), y in ys]
        ax.backgroundcolor = c_triv
        pd_topo!(ax, Φs, ys, -M; σ = (9, 5))                    # −1 is topological here
        hspan!(ax, μlimsF[1], 0; color = c_ins)
        hlines!(ax, 1; color = c_mu, linestyle = :dash, linewidth = lw_guide)
        vlines!(ax, Φc; color = c_crit, linestyle = :dash, linewidth = 2)
        ax.xticks = ([0.5, Φc, 1, 1.5], ["0.5", L"\Phi^\mathrm{c}", "1", "1.5"])
        ax.xlabel = L"\Phi/\Phi_0"
        ax.yticks = ([0, yts, 1], [L"0", L"\mu^\mathrm{ts}", L"\mu_\mathrm{bulk}"])
        ax.ylabel = L"\mu"
        ax.ylabelpadding = -4
        phase_legend!(fig, PDF.x, 0.17)
    elseif layer in (:mzm, :qmzm)
        overlay_axis!(ax)
        x = layer == :mzm ? Φ1 : Φ2
        skin = (0, yts, c_skin, 7.5)
        segs = layer == :mzm ? [(μlimsF[1], 0, c_insline, 4.5), skin, (yts, 1, c_topo, 4.5)] :
            [(μlimsF[1], 0, c_insline, 4.5), skin, (yts, ytop, c_topo, 4.5), (ytop, 1, c_ink, 4.5)]
        for (y0, y1, c, lw) in segs
            lines!(ax, [x, x], [y0, y1]; color = c, linewidth = lw, linecap = :butt)
        end
        scatter!(ax, Point2f(x, 1.0); marker = :utriangle, markersize = 20,
            color = last(segs)[3], strokecolor = :white, strokewidth = 1)
        path_ticks!(ax, x, μz_full2; Y = Yμ, labels = layer == :mzm, side = -1, skip = (2,), dx = 0.018)
        text!(ax, x + (layer == :mzm ? -0.025 : 0.025), -0.1;
            text = layer == :mzm ? L"\Phi^{(1)}" : L"\Phi^{(2)}",
            fontsize = fs_label, align = (layer == :mzm ? :right : :left, :center))
        text!(ax, x, 0.02; text = layer == :mzm ? "MZM" : "Q-MZM", fontsize = fs_tick,
            font = :semibold, rotation = π/2, align = (:left, :top), offset = (8, 0))
    else  # :skin
        overlay_axis!(ax)
        text!(ax, 1.22, 0.22; text = "Trivial\nskin", color = c_skin, font = :bold,
            fontsize = fs_axis + 2, align = (:center, :center), justification = :center)
    end
    return fig
end

# Slide 11: normal-state angular subbands at k_z = 0, Φ = Φ0/2 (paper Fig. 4b, schematic,
# m_r = 1, realistic SOC); layers :bands, :skin
const FIL = (W = 4.6, H = 4.0, x = 0.80, y = 0.12, w = 3.6, h = 3.15)
function fig_filling(layer::Symbol)
    fig = newfig(FIL.W, FIL.H)
    ax = pax(fig, FIL.x, FIL.y, FIL.w, FIL.h)
    fR(x) = 0.5 * (x - 1)^2 + 0.5
    fL(x) = 0.5 * (x + 1)^2 + 0.5
    xs = range(-2.1, 2.1, length = 200)
    xS = collect(range(-2, 2, length = 10))
    x0 = minimum(abs, xS)
    μts = fR(x0)
    Ebottom = 0.5
    xlims!(ax, -2.1, 2.1); ylims!(ax, 0.3, 1.15)
    if layer == :bands
        for (f, xJ) in ((fR, x0), (fL, -x0))
            lines!(ax, xs, f.(xs); color = c_grey, linewidth = lw_data)
            others = filter(x -> x != xJ && f(x) < 1.15, xS)
            scatter!(ax, others, f.(others); color = :white, strokecolor = c_grey, strokewidth = 2, markersize = 14)
            scatter!(ax, [xJ], [f(xJ)]; color = c_topo, markersize = 18)
        end
        text!(ax, 0.36, μts + 0.02; text = rich(rich("m"; font = :italic), subscript("J"; font = :italic), " = 0"),
            color = c_topo, fontsize = fs_label, font = :semibold, align = (:left, :bottom))
        xc, yc = -1.0, 0.985
        text!(ax, xc, yc + 0.01; text = "CdGM analogs", color = c_insline, fontsize = fs_tick,
            align = (:center, :bottom))
        sx, sy = 3.6 * 72 / 4.2, 3.15 * 72 / 0.85
        for xd in xS[2:4]
            yd = fL(xd)
            t = 1 - 11 / hypot((xd - xc) * sx, (yd - yc) * sy)
            arrows2d!(ax, [xc], [yc], [xc + t * (xd - xc)], [yc + t * (yd - yc)]; argmode = :endpoint,
                color = c_insline, shaftwidth = 1.8, tiplength = 10, tipwidth = 9)
        end
        ax.xlabel = rich(rich("m"; font = :italic), subscript("L"; font = :italic))
        ax.ylabel = rich("E"; font = :italic)
        hidexdecorations!(ax; label = false)
        ax.yticks = ([μts], [L"\mu^\mathrm{ts}"])
        ax.yticklabelcolor = :transparent
        ax.ytickcolor = :transparent
    else
        hidexdecorations!(ax); hidespines!(ax)
        ax.backgroundcolor = :transparent
        hspan!(ax, Ebottom, μts; color = (c_skin_tint, 0.75))
        hlines!(ax, μts; color = c_skin, linewidth = lw_data)
        text!(ax, 0, Ebottom - 0.025; text = "Trivial skin", color = c_skin, font = :bold, fontsize = fs_label,
            align = (:center, :top))
        ax.yticks = ([μts], [L"\mu^\mathrm{ts}"])
        ax.yticklabelcolor = c_skin; ax.ytickcolor = c_skin
        ax.yticklabelsize = fs_axis
        ax.ylabel = ""
    end
    return fig
end

# Slide 11: phase diagram μ–⟨α⟩ at Φ = Φ0/2 (paper Fig. 4c data) with the thresholds
const PMA = (W = 5.6, H = 4.0, x = 1.05, y = 0.42, w = 4.35, h = 2.83)
function fig_pd_mualpha()
    fig = newfig(PMA.W, PMA.H)
    ax = pax(fig, PMA.x, PMA.y, PMA.w, PMA.h)
    r = loadres("data/PD_mu_alpha/base_fs_alphazoom.jld2")
    cp = r.system.calc_params
    μs, αs = collect(cp.μrng), collect(cp.αrng)
    ax.backgroundcolor = c_triv
    pd_topo!(ax, μs, αs, -Float64.(r.PD); σ = (1.2, 1.2))
    vspan!(ax, -5, 0; color = c_ins)
    for (μ, c, lab) in ((1.0, c_purple, L"\mu^\mathrm{ts}_{m_r = 0}"), (21.9, c_wfL, L"\mu^\mathrm{ts}_{m_r = 1}"))
        vlines!(ax, μ; color = c, linewidth = 2)
        text!(ax, μ + 0.6, 97; text = lab, color = c, fontsize = fs_label, align = (:left, :top))
    end
    # μ(z) along this wire (⟨α⟩ = 7 meV nm): trivial up to μ^ts, topological up to μ_bulk
    α0 = 7.0
    jα = argmin(abs.(αs .- α0))
    μt = μs[findfirst(==(-1), r.PD[:, jα])]               # first topological μ at this ⟨α⟩
    lines!(ax, [0, μt], [α0, α0]; color = c_skin, linewidth = 7, linecap = :butt)
    lines!(ax, [μt, μbulkF], [α0, α0]; color = c_topo, linewidth = 4.5, linecap = :butt)
    scatter!(ax, Point2f(μbulkF, α0); marker = :rtriangle, markersize = 18, color = c_topo,
        strokecolor = :white, strokewidth = 1)
    text!(ax, 11.0, α0 + 4; text = "Trivial skin", color = c_skin, font = :bold, fontsize = fs_label,
        align = (:center, :bottom))
    text!(ax, 34.5, α0 + 4; text = rich(rich("μ(z)"; font = mathfont), ", this wire"), color = c_ink2,
        fontsize = fs_tick, align = (:right, :bottom))
    xlims!(ax, -2, 35); ylims!(ax, 0, 100)
    ax.xticks = 0:10:30
    ax.yticks = 0:25:100
    ax.xlabel = L"\mu\ \mathrm{(meV)}"
    ax.ylabel = L"\langle\alpha\rangle\ \mathrm{(meV\,nm)}"
    phase_legend!(fig, PMA.x, 0.17)
    return fig
end

# Slide 12: m_J = 0 DOS in lobe 1 (paper Fig. 1h)
const DMJ = (W = 5.1, H = 3.75, x = 0.95, y = 0.42, w = 3.95, h = 2.55)
function fig_dos_mj0()
    fig = newfig(DMJ.W, DMJ.H)
    ax = pax(fig, DMJ.x, DMJ.y, DMJ.w, DMJ.h)
    r = loadres("data/DOS/base_fs_zoom.jld2")
    cp = r.system.calc_params
    Φ = collect(cp.Φrng_DOS)
    ω = mirror_ω(real.(collect(cp.ωrng))) ./ Δ0
    heat!(ax, Φ, ω, mirror_M(r.DOS[0]); crange = (5e-2, 5e-1))
    vlines!(ax, Φc; color = c_crit, linestyle = :dash, linewidth = 2)
    xlims!(ax, 0.501, 1.499); ylims!(ax, -0.113, 0.113)
    ax.xticks = ([0.5, 1, 1.5], ["0.5", "1", "1.5"])
    ax.yticks = ([-0.1, 0, 0.1], ["−0.1", "0", "0.1"])
    ax.xlabel = L"\Phi/\Phi_0"
    ax.ylabel = L"\omega/\Delta_0"; ax.ylabelpadding = 2
    mbar!(ax, 0.505, Φc, 0.018; cap = 0.006)
    text!(ax, (0.5 + Φc) / 2, 0.026; text = "MZM", color = :white, fontsize = fs_tick, font = :semibold, align = (:center, :bottom))
    mbar!(ax, Φc, 0.98, -0.018; cap = 0.006)
    text!(ax, (Φc + 0.98) / 2, -0.026; text = "Q-MZM", color = :white, fontsize = fs_tick, font = :semibold, align = (:center, :top))
    ax.xticks = ([0.501, Φc, 1, 1.499], ["0.5", L"\Phi^\mathrm{c}", "1", "1.5"])
    top_marks!(fig, ax, [Φ1, Φ2], [L"\Phi^{(1)}", L"\Phi^{(2)}"])
    return fig
end

## ===========================================================================
## Slides 8–9: CdGM analogs
## ===========================================================================
# Cartoons: (:vortex) Abrikosov vortex, Δ(r) suppressed in the core, Andreev reflection
# at r_E where Δ(r_E) = E; (:fullshell) full shell, winding pairing around a
# semiconductor core, Andreev reflection at the core–shell interface.
const VTX = (W = 2.6, H = 2.6)
function circle_pts(r, θs; c = (0, 0))
    return [Point2f(c[1] + r * cos(θ), c[2] + r * sin(θ)) for θ in θs]
end
function winding_arrow!(ax, r; θ0 = 0.35, θ1 = 2π - 0.35, color = c_ink2, lw = 2.2)
    θs = range(θ0, θ1, 120)
    lines!(ax, circle_pts(r, θs); color, linewidth = lw)
    p = circle_pts(r, [θ1])[1]
    d = Point2f(-sin(θ1), cos(θ1))
    arrows2d!(ax, [p[1] - 0.06d[1]], [p[2] - 0.06d[2]], [0.12d[1]], [0.12d[2]]; color,
        shaftwidth = lw, tiplength = 11, tipwidth = 10)
end
# Electron–hole lens and Cooper-pair glyphs, after the thesis figure (PT_Thesis/
# PT1_Introduction/src/plotters/vortex.jl, Fig. andreev_wall), scaled for the slide.
# The e and h arrows retrace one chord (offset ±δ only so both are visible) and close at
# the two Andreev reflections (red). Each reflection moves a Cooper pair across the wall:
# e → h (right) hands a pair to the condensate, h → e (left) takes one back, so both pair
# arrows point the same way and one pair 2e crosses the core per round trip.
const c_pair = colorant"#37474F"          # neutral dark slate: the pair is not a quasiparticle
const c_wall = c_accent                   # Andreev reflection

function eh_lens!(ax, x1, x2, yc, δ; ecolor = c_skin, hcolor = c_wfR)
    xa, xb = x1 + δ, x2 - δ
    arrows2d!(ax, [xa], [yc + δ], [xb], [yc + δ]; argmode = :endpoint, color = ecolor,
        shaftwidth = 3, tipwidth = 11, tiplength = 11)
    arrows2d!(ax, [xb], [yc - δ], [xa], [yc - δ]; argmode = :endpoint, color = hcolor,
        shaftwidth = 3, tipwidth = 11, tiplength = 11)
    for (xc, θ) in ((xb, range(-π / 2, π / 2, length = 40)), (xa, range(π / 2, 3π / 2, length = 40)))
        lines!(ax, xc .+ δ .* cos.(θ), yc .+ δ .* sin.(θ); color = c_wall, linewidth = 2.2)
    end
    scatter!(ax, [x1, x2], [yc, yc]; color = c_wall, markersize = 7, strokewidth = 0)
    text!(ax, (x1 + x2) / 2, yc + δ + 0.04; text = L"e", color = ecolor, fontsize = fs_label,
        align = (:center, :bottom))
    text!(ax, (x1 + x2) / 2, yc - δ - 0.04; text = L"h", color = hcolor, fontsize = fs_label,
        align = (:center, :top))
end

# Cooper pair at (x0, y0) moving horizontally by dx: two dots ringed by an ellipse.
# arrow = :ahead: the pair leaving the wall (arrow from its far rim); :behind: the pair on
# its way in (arrow tip on its near rim). White fill and halo keep it legible on the shading.
function cooper_pair!(ax, x0, y0, dx; arrow = :ahead, sep = 0.055, ea = 0.075, kb = 2.2)
    t = range(0, 2π, length = 120)
    pts = Point2f.(x0 .+ ea .* cos.(t), y0 .+ kb * sep .* sin.(t))
    s = sign(dx)
    rim, far = x0 + s * ea, x0 - s * ea
    tail, tip = arrow === :ahead ? (rim, x0 + dx) : (far - dx, far)
    arrows2d!(ax, [tail], [y0], [tip], [y0]; argmode = :endpoint, color = :white,
        shaftwidth = 5, tipwidth = 14, tiplength = 13)
    poly!(ax, pts; color = :white, strokecolor = :white, strokewidth = 4)
    poly!(ax, pts; color = :white, strokecolor = c_pair, strokewidth = 1.6)
    arrows2d!(ax, [tail], [y0], [tip], [y0]; argmode = :endpoint, color = c_pair,
        shaftwidth = 2, tipwidth = 9, tiplength = 9)
    scatter!(ax, [x0, x0], [y0 + sep, y0 - sep]; color = c_pair, markersize = 8)
end

# The reflection cycle of one chord between ±xE: lens, the two pairs just outside the
# turning points (both moving +x), and the 2e label under the outgoing one
function andreev_cycle!(ax, xE; δ = 0.07, gap = 0.17, dx = 0.2)
    eh_lens!(ax, -xE, xE, 0.0, δ)
    cooper_pair!(ax, xE + gap, 0.0, dx; arrow = :ahead)
    cooper_pair!(ax, -xE - gap, 0.0, dx; arrow = :behind)
    text!(ax, xE + gap, -0.15; text = L"2e", color = c_pair, fontsize = fs_label - 1,
        align = (:center, :top))
end

function fig_cartoon(which::Symbol)
    fig = newfig(VTX.W, VTX.H)
    ax = pax(fig, 0.0, 0.0, VTX.W, VTX.H; aspect = DataAspect(), backgroundcolor = :transparent)
    hidedecorations!(ax); hidespines!(ax)
    limits!(ax, -1.3, 1.3, -1.3, 1.3)
    if which == :vortex
        # Δ(r) = Δ tanh(r/ξ); a state at E is turned back at r_E where Δ(r_E) = E (dashed)
        rE = 0.38
        xs = range(-1, 1, 301)
        D = [hypot(x, y) <= 1 ? tanh(hypot(x, y) / 0.38) : NaN for x in xs, y in xs]
        heatmap!(ax, xs, xs, D; colormap = [colorant"#FFFFFF", c_super, colorant"#8EA3EE"],
            colorrange = (0, 1), nan_color = :transparent, rasterize = 4)
        lines!(ax, circle_pts(1.0, range(0, 2π, 200)); color = c_ink2, linewidth = 1.2)
        lines!(ax, circle_pts(rE, range(0, 2π, 200)); color = c_wall, linewidth = 1.2, linestyle = :dash)
        andreev_cycle!(ax, rE; dx = 0.22)
        winding_arrow!(ax, 1.13)
        text!(ax, -1.27, 1.27; text = L"\Delta(r)\,e^{i\varphi}", fontsize = fs_label, align = (:left, :top))
    else
        # Andreev reflection at the core–shell interface; the pairs go into the shell
        Rc = 0.58
        lines!(ax, circle_pts(1.0, range(0, 2π, 200)); color = c_ink2, linewidth = 1.2)
        poly!(ax, circle_pts(1.0, range(0, 2π, 200)); color = c_super, strokewidth = 0)
        poly!(ax, circle_pts(Rc, range(0, 2π, 200)); color = c_semi, strokecolor = c_ink2, strokewidth = 1.2)
        andreev_cycle!(ax, Rc; gap = 0.165, dx = 0.18)
        winding_arrow!(ax, 1.13)
        text!(ax, 0.0, -0.44; text = L"\Phi", color = :red, fontsize = fs_axis + 4, align = (:center, :center))
        text!(ax, -1.27, 1.27; text = L"\Delta\,e^{in\varphi}", fontsize = fs_label, align = (:left, :top))
    end
    return fig
end

# Hollow-core bands and end LDOS (illustrative, slides/data/cdgm_bands.jld2): one row
# per flux, Φ = 0 (n = 0) and Φ = Φ0 (n = 1); layers :n0, :n1
const BND = (W = 5.9, H = 5.0, xb = 0.85, wb = 3.35, xl = 4.35, wl = 1.2, h = 1.70, y1 = 0.38, y2 = 2.55)
const ml_palette = [colorant"#23427F", colorant"#6699CC", colorant"#C8102E", colorant"#E07A00",
    colorant"#007749", colorant"#54416B"]
function fig_bands(layer::Symbol)
    fig = newfig(BND.W, BND.H)
    key, lab = layer == :n0 ? ("Phi0", L"\Phi = 0\ (n = 0)") : ("Phi075", L"\Phi = 0.75\,\Phi_0\ (n = 1)")
    d = JLD2.load("slides/data/cdgm_bands.jld2")[key]
    y = layer == :n0 ? BND.y1 : BND.y2
    Δ = d["Δ0"]; emax = 2.2
    axb = pax(fig, BND.xb, y, BND.wb, BND.h)
    axl = pax(fig, BND.xl, y, BND.wl, BND.h)
    ks = d["ks"]
    analogs = findall(d["analog"])
    for j in eachindex(d["mL"])
        isan = j in analogs
        c = isan ? ml_palette[mod1(findfirst(==(j), analogs), length(ml_palette))] : c_grey
        for b in 1:2
            lines!(axb, ks, d["sc"][:, b, j] ./ Δ; color = c, linewidth = isan ? 2.6 : 1.4)
        end
        isan && lines!(axl, d["ldos"][:, j] ./ maximum(d["ldos"]), d["ωs"] ./ Δ; color = c, linewidth = 2)
    end
    xlims!(axb, -0.035, 0.035); ylims!(axb, -emax, emax)
    xlims!(axl, 0, 1.05); ylims!(axl, -emax, emax)
    axb.yticks = ([-2, -1, 0, 1, 2], ["−2", "−1", "0", "1", "2"])
    axb.ylabel = L"E/\Delta_0"; axb.ylabelpadding = 2
    axb.xticks = ([-0.03, 0, 0.03], ["−0.03", "0", "0.03"])
    hideydecorations!(axl); hidexdecorations!(axl)
    if layer == :n1
        axb.xlabel = L"k_z\ \mathrm{(nm^{-1})}"; axb.xlabelpadding = 0
    else
        hidexdecorations!(axb; ticks = false)
    end
    cv = canvas(fig)
    text!(cv, BND.xb, BND.H - y + 0.04; text = lab, fontsize = fs_label, align = (:left, :bottom))
    text!(cv, BND.xl + BND.wl / 2, BND.H - y + 0.04; text = "end LDOS", fontsize = fs_tick,
        align = (:center, :bottom))
    return fig
end

# Deng et al. PRL 134, 206302 (2025): measured dI/dV (device 1, Fig. 2a, recovered from
# the figure PDF in PT3_CdGM) and the published model dI/dv (Fig. 3d, imported unchanged)
# Both maps are dI/dV in e²/h and share one colour scale: (0, 0.5) covers the experiment's
# recovered range (capped at the published colour-bar top, 0.49) and saturates only the
# top ~0.5% of the theory map (the published theory panel used (0, 0.4)). The one shared
# colorbar is its own picture (s09_cbar, same height, bar at the same y), so on the slide it
# can sit next to the experiment first and slide to the right of the theory (Morph).
const EXT = (W = 8.9, H = 4.45, x1 = 0.85, x2 = 4.45, w = 3.45, h = 3.0, y = 0.78)
const EXT_CB = (W = 0.85, x = 0.02)       # colorbar canvas: width, bar offset
const exp_theory_crange = (0.0, 0.5)
function json_array(s, key)
    m = match(Regex("\"$key\":\\s*\\[([^\\]]*)\\]"), s)
    return parse.(Float64, split(m[1], ','))
end
function fig_exp_theory(layer::Symbol)
    fig = newfig(EXT.W, EXT.H)
    cv = canvas(fig)
    if layer == :exp
        e = JLD2.load(joinpath(PT3, "data/prl25_exp/fig2a_dIdV.jld2"))
        crops = read(joinpath(PT3, "data/prl25_exp/raw/published_crops.json"), String)
        s = crops[findfirst("\"fig2a_dIdV\"", crops)[end]:end]
        s = s[1:findfirst('}', s)]
        Bw, Vw = json_array(s, "B_T"), json_array(s, "V_mV")
        ax = pax(fig, EXT.x1, EXT.y, EXT.w, EXT.h)
        heat!(ax, e["x"], e["y"], e["z"]; crange = exp_theory_crange)
        limits!(ax, Bw..., Vw...)
        ax.xlabel = L"B\ \mathrm{(T)}"; ax.ylabel = L"V\ \mathrm{(mV)}"; ax.ylabelpadding = 2
        ax.xticks = ([0, 0.1, 0.2, 0.3], ["0", "0.1", "0.2", "0.3"])
        ax.yticks = ([-0.2, 0, 0.2], ["−0.2", "0", "0.2"])
        Bp = 0.13000607739948433
        top_marks!(fig, ax, [0, Bp, 2Bp], [L"0", L"\Phi_0", L"2\Phi_0"])
        text!(cv, EXT.x1 + EXT.w / 2, EXT.H - 0.04; text = "Experiment", font = :semibold,
            fontsize = fs_title, align = (:center, :top))
    else
        t = JLD2.load(joinpath(PT3, "data/prl25/conductance.jld2"))
        G = sum(values(t["maps"]))
        ax = pax(fig, EXT.x2, EXT.y, EXT.w, EXT.h)
        heat!(ax, t["Φ"], t["ω"], G; crange = exp_theory_crange)
        Bw = (-0.0925, 0.3325)
        Rlp = 72.0                                          # nm, theory (PRL Fig. 3)
        Φper = π * (Rlp * 1e-9)^2 / 2.067833848e-15          # Φ/Φ0 per tesla
        limits!(ax, (Bw .* Φper)..., -0.325, 0.325)
        ax.xlabel = L"\Phi/\Phi_0"
        ax.xticks = ([0, 1, 2], ["0", "1", "2"])
        ax.yticks = ([-0.2, 0, 0.2], ["−0.2", "0", "0.2"])
        hideydecorations!(ax; ticks = false)
        text!(cv, EXT.x2 + EXT.w / 2, EXT.H - 0.04; text = "Theory", font = :semibold,
            fontsize = fs_title, align = (:center, :top))
    end
    return fig
end

function fig_exp_theory_cbar()
    fig = newfig(EXT_CB.W, EXT.H)
    cb = colorbar_axis!(fig, EXT_CB.x, EXT.y, 0.12, EXT.h; label = L"dI/dV\ (e^2/h)")
    cb.yticks = ([0, 1], ["0", "$(exp_theory_crange[2])"])
    return fig
end

## ===========================================================================
## Slide 16 (conclusions): small panels without axes
## ===========================================================================
const THB = (W = 2.4, H = 1.35)
function fig_thumb(which::Symbol)
    fig = newfig(THB.W, THB.H; transparent = false)
    ax = pax(fig, 0.02, 0.02, THB.W - 0.04, THB.H - 0.04)
    if which == :skin
        realspace!(ax, :full, :qmajo; zl = (-1.0, 9.0), fs = 12, minimal = true)
        hidexdecorations!(ax)
    else
        name = which == :partial ? "base_partial_szoom" : "base_fs_szoom"
        ldos_chi!(ax, name, "QMajo")
        hidedecorations!(ax)
        which == :partial ? tag!(ax, "False positive", c_topo; fontsize = 12, y = 0.95) :
                            tag!(ax, "No false positive", c_skin; fontsize = 12, y = 0.95)
    end
    return fig
end

# Numbers quoted on the slides and backups, from the same data as the figures
function write_numbers()
    nums = Dict(
        "Phi_c" => Φc,
        "partial_topo_end_chi" => PH.zP_topo_end,          # V_Z^(2): topological for 0 < z < this
        "full_skin_end_chi_Phi1" => PH.zF1_skin_end,       # Φ^(1): trivial skin for 0 < z < this
        "full_skin_end_chi_Phi2" => PH.zF_skin_end,        # Φ^(2)
        "full_topo_end_chi_Phi2" => PH.zF_topo_end,
        "mu_ts_over_mubulk_Phi2" => PH.μts,
        "chi_vanish_full_MZM_nm" => χ_vanish("base_fs_szoom", "Majo"),
        "chi_vanish_full_QMZM_nm" => χ_vanish("base_fs_szoom", "QMajo"),
    )
    open(joinpath(figdir, "numbers.json"), "w") do io
        println(io, "{")
        ks = sort(collect(keys(nums)))
        for (i, k) in enumerate(ks)
            println(io, "  \"$k\": ", round(nums[k]; sigdigits = 4), i < length(ks) ? "," : "")
        end
        println(io, "}")
    end
    return nums
end

## ===========================================================================
## Render
## ===========================================================================
const FIGS = Dict{String, Function}(
    # slides 3–6, partial shell
    "s03_pd_partial" => () -> fig_pd_partial(:base),
    "s04_pd_partial_mzm" => () -> fig_pd_partial(:mzm),
    "s04_pd_partial_qmzm" => () -> fig_pd_partial(:qmzm),
    "s03_ldos_vB_sharp" => () -> fig_ldos_vB(:sharp),
    "s06_ldos_vB_smooth" => () -> fig_ldos_vB(:smooth),
    "s04_cut_partial" => () -> fig_cut(:partial),
    "s04_rs_partial_majo" => () -> fig_rs(:partial, :majo),
    "s04_rs_partial_bare" => () -> fig_rs(:partial, :majo; bare = true),
    "s04_rs_partial_qmajo" => () -> fig_rs(:partial, :qmajo),
    "s05_dos_partial" => fig_dos_partial,
    "s05_rs_smooth" => () -> fig_rs_chi(:smooth),
    "s05_rs_sharp" => () -> fig_rs_chi(:sharp),
    "s05_dos_smooth" => () -> fig_dos_row(:smooth),
    "s05_dos_sharp" => () -> fig_dos_row(:sharp),
    "s06_ldos_chi_partial_majo" => () -> fig_ldos_chi_partial(:majo),
    "s06_ldos_chi_partial_qmajo" => () -> fig_ldos_chi_partial(:qmajo),
    "s06_ldos_chi_partial_tag" => () -> fig_ldos_chi_partial(:tag),
    # slides 7–9, full-shell basics
    "s08_cartoon_vortex" => () -> fig_cartoon(:vortex),
    "s08_cartoon_fullshell" => () -> fig_cartoon(:fullshell),
    "s08_bands_n0" => () -> fig_bands(:n0),
    "s08_bands_n1" => () -> fig_bands(:n1),
    "s09_exp" => () -> fig_exp_theory(:exp),
    "s09_theory" => () -> fig_exp_theory(:theory),
    "s09_cbar" => fig_exp_theory_cbar,
    "s10_dos_lobes_total" => () -> fig_dos_lobes(:total),
    "s10_dos_lobes_mj0" => () -> fig_dos_lobes(:mj0),
    # slides 11–15, full shell with smooth confinement
    "s11_cut_full" => () -> fig_cut(:full; zl = (-1.0, 9.0)),
    "s11_pd_full" => () -> fig_pd_full(:base),
    "s11_pd_full_mzm" => () -> fig_pd_full(:mzm),
    "s11_pd_full_qmzm" => () -> fig_pd_full(:qmzm),
    "s11_pd_full_skin" => () -> fig_pd_full(:skin),
    "s12_filling_bands" => () -> fig_filling(:bands),
    "s12_filling_skin" => () -> fig_filling(:skin),
    "s12_pd_mualpha" => fig_pd_mualpha,
    "s13_rs_full_majo" => () -> fig_rs(:full, :majo; zl = (-1.0, 9.0)),
    "s13_rs_full_qmajo" => () -> fig_rs(:full, :qmajo; zl = (-1.0, 9.0)),
    "s13_dos_mj0" => fig_dos_mj0,
    "s14_grid_partial" => () -> fig_ldos_grid(:partial),
    "s14_grid_fullM" => () -> fig_ldos_grid(:fullM),
    "s14_grid_fullQ" => () -> fig_ldos_grid(:fullQ),
    "s14_grid_ann" => () -> fig_ldos_grid(:ann),
    "s14_grid_tagP" => () -> fig_ldos_grid(:tagP),
    "s14_grid_tagF" => () -> fig_ldos_grid(:tagF),
    "s14_grid_cbarF" => fig_ldos_grid_cbar,
    "s15_disorder_partial" => () -> fig_disorder(:partial),
    "s15_disorder_full" => () -> fig_disorder(:full),
    # slide 16, conclusions
    "s16_thumb_partial" => () -> fig_thumb(:partial),
    "s16_thumb_skin" => () -> fig_thumb(:skin),
    "s16_thumb_full" => () -> fig_thumb(:full),
)

if abspath(PROGRAM_FILE) == @__FILE__
    names = isempty(ARGS) ? sort(collect(keys(FIGS))) :
        sort([k for k in keys(FIGS) if any(a -> startswith(k, a), ARGS)])
    for n in names
        export_fig(FIGS[n](), n)
        println("  ", n)
    end
    isempty(ARGS) || "numbers" in ARGS ? println(write_numbers()) : nothing
end
