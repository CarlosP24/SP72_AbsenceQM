# Poster figures (ICTP–WE Heraeus College, Trieste, Oct 2026)
# Renders hero_A.pdf, hero_B.pdf, fig2.pdf (+ 150 dpi PNG previews) from repo data.
# Run from anywhere: julia plots/poster_figs/make_poster_figs.jl
cd(joinpath(@__DIR__, "..", ".."))
using Pkg
Pkg.activate("plots")
using CairoMakie, Parameters, JLD2
using Quantica, FullShell
using FunctionZeros, SpecialFunctions, LinearAlgebra

include(joinpath(pwd(), "src/utilities.jl"))
include_all("../plots/plotters")
include_all("builders")
include(joinpath(pwd(), "src/models/models.jl"))

const outdir = "plots/poster_figs"

## ---------------------------------------------------------------------------
## Format and palette
## ---------------------------------------------------------------------------
const mm = 72 / 25.4

const fs_tick  = 22
const fs_label = 26
const fs_axis  = 32                     # axis labels
const fs_title = 28
const fs_row   = 30

const lw_data  = 2.5
const lw_wf    = 3
const lw_spine = 1.5
const lw_guide = 1

const c_topo      = colorant"#C8102E"   # PANTONE 186 C
const c_topo_tint = colorant"#EE9DA9"
const c_skin      = colorant"#007749"   # PANTONE 3415 C
const c_skin_tint = colorant"#B3D6C8"   # ~30 % tint of 3415 C
const c_ins       = colorant"#BDBDBD"
const c_triv      = colorant"#F4F4F4"
const c_wfL       = colorant"#8B0000"   # paper's :darkred
const c_wfR       = colorant"#1B5E20"   # darker than skin green
const c_grey      = colorant"#8C8C8C"
const c_insline   = colorant"#555555"   # trajectory segment inside the Ins region

const Δ0 = 0.23
const cmap = :thermal
const ldos_max = 1e-2                    # shared LDOS normalisation (all heatmaps)

axis_style = (
    xticklabelsize = fs_tick, yticklabelsize = fs_tick,
    xlabelsize = fs_axis, ylabelsize = fs_axis,
    spinewidth = lw_spine, xtickwidth = lw_spine, ytickwidth = lw_spine,
    xgridvisible = false, ygridvisible = false,
)

## ---------------------------------------------------------------------------
## Data: local phases along z
## ---------------------------------------------------------------------------
# Transitions of a phase-diagram column (returns μ values where PD flips)
function pd_transitions(μs, col)
    idx = findall(col[1:end-1] .!= col[2:end])
    return [(μs[i] + μs[i+1]) / 2 for i in idx]
end

# Partial shell: Eq. (A2), μ(z) = μ_bulk (1 - e^{-z/χ})
μz_partial(z) = 1 - exp(-z)                       # z in units of χ, μ in units of μ_bulk

# Full shell: Bessel barrier of build_barrier projected on the m_J = 0, m_r = 1
# radial mode (normal state, k_z = 0, Φ^(2)); μ_eff(z) = μ_bulk - ⟨U(z, r)⟩
function μz_full_factory(; Φ = 0.88)
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
const μz_full = μz_full_factory()

# z/χ where μ(z)/μ_bulk crosses y (monotonic bisection)
function z_of_μ(f, y; lo = 0.0, hi = 30.0)
    for _ in 1:80
        mid = (lo + hi) / 2
        f(mid) < y ? (lo = mid) : (hi = mid)
    end
    return (lo + hi) / 2
end

function phase_data()
    @load "data/PD_mu_B/base_partial.jld2" res
    cp = res.system.calc_params
    j = argmin(abs.(cp.Brng .- 1.8))
    μc_partial = maximum(pd_transitions(cp.μrngP, res.PD[:, j])) / 2      # / μ_bulk
    @load "data/PD_mu_flux/base_fs_zoom.jld2" res
    cp = res.system.calc_params
    j = argmin(abs.(cp.Φrng_PD .- 0.88))
    μts, μtop = pd_transitions(cp.μrng, res.PD[:, j]) ./ 22.8
    return (;
        μc_partial, μts, μtop,
        zP_topo_end = z_of_μ(μz_partial, μc_partial),
        zF_skin_end = z_of_μ(μz_full, μts),
        zF_topo_end = z_of_μ(μz_full, μtop),
    )
end
const PH = phase_data()

## ---------------------------------------------------------------------------
## Panels
## ---------------------------------------------------------------------------
const zlims = (-1.0, 9.0)

# Real-space strip layout (data y-units): |Ψ|² in [0, wf_scale], band bottom above it
const wf_scale = 0.9
const yE0, hE = 0.0, 1.35           # band-bottom baseline (shared with |Ψ|²) and height of μ
const y_lbl = 2.22                  # phase labels
const lw_rs = 4.5                   # wavefunctions in the real-space strip
const lw_barrier = 4

# Band bottom E_c(z) in units of μ_bulk (0 deep in the wire, μ_bulk at the line labelled μ).
# z ≥ 0: E_c = 1 - μ(z)/μ_bulk from the barrier model. z < 0: schematic electrostatic barrier
# of the uncovered section (as in paper Fig. 1a,d), a smooth bump peaking at ≈1.5 μ_bulk,
# matched in value and slope to the wire side at z = 0.
function band_bottom(μz)
    e0 = 1 - μz(0.0)
    s0 = -(μz(1e-3) - μz(0.0)) / 1e-3            # slope of E_c at z = 0⁺
    # quartic p(t), t = z + 1: p(0) = p'(0) = 0, p(1) = e0, p'(1) = s0, peak ≈ 1.5
    a = 16e0
    c = a + s0 - 3e0
    b = e0 - a - c
    p(t) = a * t^2 + b * t^3 + c * t^4
    return z -> z >= 0 ? 1 - μz(z) : p(z + 1)
end

function band_label!(ax, x, txt; color = :black, font = :regular, y = y_lbl)
    text!(ax, x, y; text = txt, color, font, fontsize = fs_tick, align = (:center, :center))
end

function realspace!(ax, shell::Symbol)
    zmin, zmax = zlims
    vspan!(ax, zmin, 0; color = c_ins)
    if shell == :partial
        z1 = PH.zP_topo_end
        vspan!(ax, 0, z1; color = c_topo_tint)
        vspan!(ax, z1, zmax; color = c_triv)
        band_label!(ax, z1 / 2, "Topological")
        band_label!(ax, (z1 + zmax) / 2, "Trivial")
        name, χ, μz = "base_partial", 200, μz_partial
    else
        z1, z2 = PH.zF_skin_end, PH.zF_topo_end
        vspan!(ax, 0, z1; color = c_skin_tint)
        vspan!(ax, z1, z2; color = c_topo_tint)
        vspan!(ax, z2, zmax; color = c_triv)
        vlines!(ax, [0, z1]; color = c_skin, linewidth = lw_spine)
        band_label!(ax, z1 / 2, "Trivial skin"; color = c_skin, font = :bold)
        band_label!(ax, (z1 + z2) / 2, "Topological")
        band_label!(ax, (z2 + zmax) / 2, "Trivial")
        name, χ, μz = "base_fs", 1000, μz_full
    end
    text!(ax, zmin / 2, 0.55; text = "Insulator", rotation = π/2, fontsize = fs_tick,
        align = (:center, :center))

    # Barrier: band bottom eφ_g(z) and chemical potential μ
    Ec = band_bottom(μz)
    zs = range(zmin, zmax, length = 800)
    hlines!(ax, yE0 + hE; color = :black, linestyle = :dash, linewidth = 2.5)
    text!(ax, zmax - 0.1, yE0 + hE; text = L"\mu", fontsize = fs_label, align = (:right, :bottom))
    lines!(ax, zs, yE0 .+ hE .* Ec.(zs); color = :black, linewidth = lw_barrier)
    text!(ax, 0.3, yE0 + hE + 0.04; text = L"e\phi_g(z)", fontsize = fs_tick,
        align = (:left, :bottom))

    # Decay length χ of the barrier: dimension bar from z = 0 to z = χ, ending on the curve
    # (drawn in the full-shell strip, where 0 < z < χ is free of wavefunction weight)
    if shell == :full
        yχ = yE0 + hE * Ec(1.0)
        lines!(ax, [0, 1], [yχ, yχ]; color = :black, linewidth = 3)
        for x in (0, 1)
            lines!(ax, [x, x], [yχ - 0.07, yχ + 0.07]; color = :black, linewidth = 3)
        end
        text!(ax, 0.5, yχ - 0.015; text = L"\chi", fontsize = fs_title, align = (:center, :top))
    end

    # Quasi-MZM wavefunctions, each normalised to its own maximum
    @load "data/wfs/$(name).jld2" res
    ΨL, ΨR = res.Psis["QMajo"]
    z = (0:length(ΨL)-1) .* 5 ./ χ
    keep = z .<= zmax
    # leading/trailing tails below 0.3 % of the peak are not drawn, so the humps don't
    # overlap along y = 0 (the curve stays continuous between its first and last point above)
    function tailcut(Ψ)
        y = Ψ[keep] ./ maximum(Ψ)
        i0, i1 = findfirst(>(3e-3), y), findlast(>(3e-3), y)
        return [i0 <= i <= i1 ? wf_scale * y[i] : NaN for i in eachindex(y)]
    end
    lines!(ax, z[keep], tailcut(ΨL); color = c_wfL, linewidth = lw_rs)
    lines!(ax, z[keep], tailcut(ΨR); color = c_wfR, linewidth = lw_rs)
    zL, zR = z[argmax(ΨL)], z[argmax(ΨR)]
    labL, labR = L"|\Psi_\mathrm{L}|^2", L"|\Psi_\mathrm{R}|^2"
    if shell == :partial
        text!(ax, zL + 0.4, 1.08; text = labL, color = c_wfL, fontsize = fs_label, align = (:left, :center))
        text!(ax, zR + 0.75, 0.8wf_scale; text = labR, color = c_wfR, fontsize = fs_label, align = (:left, :center))
    else
        text!(ax, zL - 0.3, 0.8wf_scale; text = labL, color = c_wfL, fontsize = fs_label, align = (:right, :center))
        text!(ax, zR - 1.2, 0.8wf_scale; text = labR, color = c_wfR, fontsize = fs_label, align = (:right, :center))
    end

    xlims!(ax, zlims...)
    ylims!(ax, -0.05, 2.42)
    ax.xticks = 0:2:8
    hideydecorations!(ax)
    return ax
end

# Device sketch (paper Fig. 1a,d): longitudinal cut aligned with z/χ
function sketch!(pos, shell::Symbol)
    ax = Axis(pos; backgroundcolor = :transparent)
    hidedecorations!(ax); hidespines!(ax)
    zend = zlims[2]
    ySM = (0.3, 0.64)
    ymid = sum(ySM) / 2
    band!(ax, [-1, -0.75], ySM...; color = color_probe)
    band!(ax, [-0.75, zend], ySM...; color = color_semi)
    band!(ax, [0, zend], ySM[2], ySM[2] + 0.3; color = color_super)
    shell == :full && band!(ax, [0, zend], ySM[1] - 0.3, ySM[1]; color = color_super)
    text!(ax, -0.95, ySM[2] + 0.04; text = "probe", fontsize = fs_tick, align = (:left, :bottom))
    text!(ax, 0.2, ySM[2] + 0.15; text = "SC", fontsize = fs_tick, align = (:left, :center))
    text!(ax, 0.2, ymid; text = "SM", fontsize = fs_tick, align = (:left, :center))
    arrows2d!(ax, [2.5], [ymid], [5.5], [ymid]; argmode = :endpoint, color = :red,
        shaftwidth = 4, tiplength = 18, tipwidth = 18)
    text!(ax, 5.7, ymid; text = L"B", color = :red, fontsize = fs_label, align = (:left, :center))
    # the real-space strip shows the Q-MZM case
    text!(ax, 6.7, ymid; text = shell == :partial ? L"V_\mathrm{Z} = V_\mathrm{Z}^{(2)}" : L"\Phi = \Phi^{(2)}",
        color = :red, fontsize = fs_label, align = (:left, :center))
    ylims!(ax, 0, 1)
    return ax
end

# 3D render of the wire (paper Fig. 1a,d)
function device!(pos, shell::Symbol)
    ax = Axis(pos; aspect = DataAspect(), backgroundcolor = :transparent)
    img = load(shell == :partial ? "plots/sketches/partial-shell.png" : "plots/sketches/full-shell.png")
    image!(ax, reverse(img, dims = 1)')
    # flux threading the full-shell cross-section, marked on the core face
    shell == :full && text!(ax, 178, size(img, 1) - 195; text = L"\Phi", color = :red,
        fontsize = 48, align = (:center, :center))
    hidedecorations!(ax); hidespines!(ax)
    return ax
end

function load_ldos(name, key)
    @load "data/LDOS/$(name).jld2" res
    @unpack χrng, ωrng = res.system.calc_params
    ω = real.(ωrng)
    ω = vcat(ω, -reverse(ω)[2:end]) ./ Δ0
    M = res.LDOS[key]
    M = cat(M, reverse(M, dims = 2)[:, 2:end], dims = 2)
    return collect(χrng), ω, M
end

# χ beyond which the end-LDOS signal of a panel stays below `frac` of its maximum
function χ_vanish(name, key; frac = 0.01)
    χ, ω, M = load_ldos(name, key)
    pk = vec(maximum(M, dims = 2))
    return χ[findlast(pk .>= frac * maximum(pk)) + 1]
end

# ωmax: energy half-range (Δ₀). The full-shell row is zoomed ~3× so that its true-MZM
# zero-energy line has the same apparent thickness as the partial-shell one.
function ldos_panel!(ax, name, key; ωmax = 0.2, ωticks = [-0.2, 0, 0.2])
    χ, ω, M = load_ldos(name, key)
    heatmap!(ax, χ, ω, M; colormap = cmap, colorrange = (0, ldos_max),
        highclip = last(to_colormap(cmap)), rasterize = 5)
    ax.xscale = log10
    xlims!(ax, 1, maximum(χ))
    ylims!(ax, -ωmax, ωmax)
    ax.xticks = ([1, 10, 100, 1000], ["1", "10", "100", "1000"])
    ax.yticks = ωticks
    return ax
end

# NEW: hidden quasi-MZM energy (data/E_QMZM, computed with src/calculations/E_QMZM.jl)
# Only states localised near the probe end are kept (⟨z⟩ < 8χ); for smaller χ the
# lowest state of the closed wire is the delocalised bulk gap edge, not a Q-MZM.
function hidden_state!(ax, name; key = "QMajo", zcmax = 8)
    path = "data/E_QMZM/$(name).jld2"
    isfile(path) || (@warn "Missing $path: hidden-state overlay skipped"; return nothing)
    @load path res
    χ = res.system.calc_params.χrng
    @unpack E, zc = res.E[key]
    e = ifelse.((zc .< zcmax) .& (E .> 0), E ./ Δ0, NaN)
    for s in (1, -1)
        lines!(ax, χ, s .* e; color = :white, linestyle = :dash, linewidth = lw_data)
    end
    return χ, e
end

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

function verdict!(pos, color, title, body)
    ax = Axis(pos; backgroundcolor = :transparent)
    hidedecorations!(ax); hidespines!(ax)
    xlims!(ax, 0, 1); ylims!(ax, 0, 1)
    poly!(ax, rounded_rect(0.02, 0.12, 0.96, 0.76, 0.08); color)
    text!(ax, 0.5, 0.66; text = title, color = :white, font = :bold, fontsize = 28,
        align = (:center, :center))
    text!(ax, 0.5, 0.36; text = body, color = :white, fontsize = 26,
        align = (:center, :center), justification = :center)
    return ax
end

const check_marker = BezierPath([
    MoveTo(Point2f(-0.50, 0.05)), LineTo(Point2f(-0.32, 0.23)), LineTo(Point2f(-0.12, 0.02)),
    LineTo(Point2f(0.36, 0.50)), LineTo(Point2f(0.54, 0.32)), LineTo(Point2f(-0.12, -0.34)),
    ClosePath()])

function mark!(ax, ok::Bool)
    scatter!(ax, Point2f(0.93, 0.85); space = :relative,
        marker = ok ? check_marker : :xcross, markersize = 40,
        color = ok ? c_skin : c_topo, strokecolor = :white, strokewidth = 2)
end

## ---------------------------------------------------------------------------
## Hero figure, 771 × 240 mm
## ---------------------------------------------------------------------------
function hero(; verdict = true)
    W, H = 771, 240
    fig = Figure(size = (W * mm, H * mm), figure_padding = 4mm, fontsize = fs_tick,
        backgroundcolor = :white)

    cols = verdict ? (dev = 2, rs = 3, mzm = 4, qmzm = 5, ver = 6, cb = 7) :
                     (dev = 2, rs = 3, mzm = 4, qmzm = 5, ver = 0, cb = 6)

    axs = Dict{Tuple{Int,Int},Axis}()
    ωscale = Dict(:partial => (ωmax = 0.2, ωticks = ([-0.2, 0, 0.2], ["−0.2", "0", "0.2"])),
                  :full => (ωmax = 0.07, ωticks = ([-0.05, 0, 0.05], ["−0.05", "0", "0.05"])))
    for (r, shell, lname) in ((1, :partial, "base_partial_szoom"), (2, :full, "base_fs_szoom"))
        gl = fig[r, cols.rs] = GridLayout()
        ax = Axis(gl[2, 1]; axis_style..., xlabel = L"z/\chi")
        realspace!(ax, shell)
        axsk = sketch!(gl[1, 1], shell)
        linkxaxes!(axsk, ax)
        xlims!(axsk, zlims...)
        xlims!(ax, zlims...)
        rowsize!(gl, 1, Auto(0.4))
        device!(fig[r, cols.dev], shell)
        rowgap!(gl, 1, 2mm)
        axs[(r, cols.rs)] = ax

        ax = Axis(fig[r, cols.mzm]; axis_style..., xlabel = L"\chi\ \mathrm{(nm)}", ylabel = L"\omega/\Delta_0",
            yticklabelspace = 62.0,        # same in both rows so the ω/Δ₀ labels line up
            ylabelpadding = -12)
        ldos_panel!(ax, lname, "Majo"; ωscale[shell]...)
        axs[(r, cols.mzm)] = ax

        ax = Axis(fig[r, cols.qmzm]; axis_style..., xlabel = L"\chi\ \mathrm{(nm)}")
        ldos_panel!(ax, lname, "QMajo"; ωscale[shell]...)
        hideydecorations!(ax; ticks = false)
        axs[(r, cols.qmzm)] = ax
    end

    # Field / flux of each LDOS panel (paper Fig. 1c,h marks)
    for (r, c, lab) in ((1, cols.mzm, L"V_\mathrm{Z} = V_\mathrm{Z}^{(1)}"), (1, cols.qmzm, L"V_\mathrm{Z} = V_\mathrm{Z}^{(2)}"),
                        (2, cols.mzm, L"\Phi = \Phi^{(1)}"), (2, cols.qmzm, L"\Phi = \Phi^{(2)}"))
        text!(axs[(r, c)], 0.6, 0.96; space = :relative, text = lab, color = :white,
            fontsize = fs_label, align = (:center, :top))
    end

    # Hidden quasi-MZM in the full shell (NEW)
    hidden_state!(axs[(2, cols.qmzm)], "base_fs_szoom")
    text!(axs[(2, cols.qmzm)], 0.97, 0.43; space = :relative,
        text = "Q-MZM exists,\ninvisible at end", color = :white, fontsize = fs_tick,
        align = (:right, :top), justification = :right)

    # Full shell: χ* where the end signal vanishes (both panels), separating the two regimes
    χstar = max(χ_vanish("base_fs_szoom", "Majo"), χ_vanish("base_fs_szoom", "QMajo"))
    for c in (cols.mzm, cols.qmzm)
        vlines!(axs[(2, c)], χstar; color = :white, linestyle = :dash, linewidth = lw_data)
    end
    axF = axs[(2, cols.mzm)]
    text!(axF, χstar / 1.25, -0.062; text = "sharp end:\nprobe works", color = :white,
        fontsize = fs_tick, align = (:right, :bottom), justification = :right)
    text!(axF, χstar * 1.25, -0.062; text = "smooth end:\ntrivial skin hides all", color = :white,
        fontsize = fs_tick, align = (:left, :bottom), justification = :left)

    # Shared x axes per column: x label only on the bottom row
    for c in (cols.rs, cols.mzm, cols.qmzm)
        linkxaxes!(axs[(1, c)], axs[(2, c)])
        hidexdecorations!(axs[(1, c)]; ticks = false)
    end

    # Column titles
    Label(fig[0, cols.dev], "Device"; fontsize = fs_title, tellwidth = false)
    Label(fig[0, cols.rs], "Real space"; fontsize = fs_title, tellwidth = false)
    Label(fig[0, cols.mzm], "True MZM"; fontsize = fs_title, tellwidth = false)
    Label(fig[0, cols.qmzm], "Quasi-MZM"; fontsize = fs_title, tellwidth = false)

    # Row titles in the left gutter
    Label(fig[1, 1], "Partial shell"; rotation = π/2, fontsize = fs_row, font = :bold, tellheight = false)
    Label(fig[2, 1], "Full shell"; rotation = π/2, fontsize = fs_row, font = :bold, tellheight = false)

    if verdict
        verdict!(fig[1, cols.ver], c_topo, "False positive", "ZEP looks\nlike an MZM")
        verdict!(fig[2, cols.ver], c_skin, "No false\npositive", "impostor buried\nby trivial skin")
    else
        mark!(axs[(1, cols.qmzm)], false)
        mark!(axs[(2, cols.qmzm)], true)
        # sans text like the other annotations; arrows taken from the bundled math font
        mathfont = joinpath(dirname(pathof(Makie.MathTeXEngine)), "..", "assets", "fonts",
            "NewComputerModern", "NewCMMath-Regular.otf")
        arrow(c) = rich(" $(c) "; font = mathfont)
        for (r, lab) in ((1, rich("ZBP", arrow("⇒"), "?")), (2, rich("ZBP", arrow("⇏"), "Q-MZM")))
            text!(axs[(r, cols.qmzm)], 0.97, 0.76; space = :relative, text = lab, color = :white,
                fontsize = fs_label, align = (:right, :top))
        end
    end

    # One colorbar per row (same normalisation); label pulled in between the tick labels
    for r in 1:2
        Colorbar(fig[r, cols.cb]; colormap = cmap, limits = (0, 1), ticks = ([0, 1], ["0", "1"]),
            label = "LDOS (arb. u.)", labelsize = fs_label, ticklabelsize = fs_tick,
            spinewidth = lw_spine, tickwidth = lw_spine, labelpadding = -16, width = 6mm)
    end

    widths = verdict ? [0.035, 0.09, 0.29, 0.2, 0.2, 0.11, 0.03] :
                       [0.035, 0.10, 0.33, 0.24, 0.24, 0.03]
    widths ./= sum(widths)
    for (c, w) in enumerate(widths)
        colsize!(fig.layout, c, Auto(w))
    end
    colgap!(fig.layout, 6mm)
    colgap!(fig.layout, 1, 2mm)
    colgap!(fig.layout, cols.mzm, 3mm)
    rowgap!(fig.layout, 1, 3mm)
    rowgap!(fig.layout, 2, 5mm)
    return fig
end

## ---------------------------------------------------------------------------
## Fig. 2, 373 × 150 mm: why the skin appears
## ---------------------------------------------------------------------------
const μlims = (-0.2, 1.1)

# Piecewise-coloured vertical trajectory at fixed x, from μ = μlims[1] to μ_bulk
function trajectory!(ax, x, segments)
    for (y0, y1, color, lw) in segments
        lines!(ax, [x, x], [y0, y1]; color, linewidth = lw, linecap = :butt)
    end
    tipcolor = last(segments)[3]          # arrowhead coloured by the bulk phase reached
    scatter!(ax, Point2f(x, 1.0); marker = :utriangle, markersize = 24, color = tipcolor,
        strokecolor = :white, strokewidth = 1)
end

# Labels on z = χ, 2χ, 3χ ticks. valign lets close-by labels spread up/down from their tick.
function ticks_on_trajectory!(ax, x, μz; Y = identity, side = 1,
        labels = (L"\chi", L"2\chi", L"3\chi"), valigns = (:center, :center, :center))
    for (n, lab, va) in zip(1:3, labels, valigns)
        y = Y(μz(n))
        lines!(ax, [x - 0.025, x + 0.025], [y, y]; color = :black, linewidth = 2)
        lab === nothing && continue
        text!(ax, x + side * 0.055, y; text = lab, fontsize = fs_tick,
            align = (side > 0 ? :left : :right, va))
    end
end

# Schematic μ axis of the full-shell panel (no scale shown): the trivial skin
# 0 → μ^ts is compressed into the lower half, the narrow μ^ts → μ_bulk window (0.026 μ_bulk)
# is stretched over the upper half. The kink at μ^ts is rounded (softplus, width w) so phase
# boundaries crossing it stay smooth. μ = 0 ↦ 0 and μ = μ_bulk ↦ 1.
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

function pd_partial!(ax)
    # linear μ axis (μ/μ_bulk), no scale shown
    @load "data/PD_mu_B/base_partial.jld2" res
    cp = res.system.calc_params
    x = cp.Brng ./ 2
    y = cp.μrngP ./ 2
    heatmap!(ax, x, y, res.PD'; colormap = [c_triv, c_topo_tint], colorrange = (-1, 1), interpolate = true, rasterize = 5)
    hspan!(ax, μlims[1], 0; color = c_ins)
    hlines!(ax, 1; color = :black, linestyle = :dash, linewidth = lw_guide)
    text!(ax, 1.98, 1.0; text = L"\mu_\mathrm{bulk}", align = (:right, :bottom), fontsize = fs_tick)

    B1, B2 = 1.5, 0.9
    # MZM: Ins → Topo all the way up
    trajectory!(ax, B1, [(μlims[1], 0, c_insline, 4), (0, 1, c_topo, 4)])
    # Q-MZM: Ins → Topo → Triv
    μc = PH.μc_partial
    trajectory!(ax, B2, [(μlims[1], 0, c_insline, 4), (0, μc, c_topo, 4), (μc, 1, :black, 4)])
    ticks_on_trajectory!(ax, B2, μz_partial; side = -1)
    ticks_on_trajectory!(ax, B1, μz_partial; labels = (nothing, nothing, nothing))

    xlims!(ax, 0, 2)
    ax.xticks = ([0, B2, B1, 2], ["0", L"V_\mathrm{Z}^{(2)}", L"V_\mathrm{Z}^{(1)}", "2"])
    ax.xlabel = L"V_\mathrm{Z}/V_\mathrm{Z}^\mathrm{c}"
    ax.ylabel = L"\mu"
    hideydecorations!(ax; label = false)
end

function pd_full!(ax)
    μts, μtop = PH.μts, PH.μtop

    # resample the PD on a regular grid of the display coordinate; fine zoom (21–24 meV)
    # where available, coarse PD (0–60 meV) elsewhere
    @load "data/PD_mu_flux/base_fs_zoom.jld2" res
    Φs, μz_, PDz = res.system.calc_params.Φrng_PD, res.system.calc_params.μrng, res.PD
    @load "data_unpublished/PD_mu_flux/base_fs.jld2" res
    μc_, PDc = res.system.calc_params.μrng, res.PD
    ys = range(0, μlims[2], length = 1200)
    # linear interpolation in μ (smooth boundaries after the stretch)
    function lerp(v, col, x)
        i = clamp(searchsortedlast(v, x), 1, length(v) - 1)
        t = clamp((x - v[i]) / (v[i+1] - v[i]), 0, 1)
        return (1 - t) * col[i] + t * col[i+1]
    end
    M = [begin
            μ = 22.8 * Yμinv(y)
            first(μz_) <= μ <= last(μz_) ? lerp(μz_, view(PDz, :, j), μ) : lerp(μc_, view(PDc, :, j), μ)
         end for j in eachindex(Φs), y in ys]
    heatmap!(ax, Φs, ys, M; colormap = [c_topo_tint, c_triv], colorrange = (-1, 1),
        interpolate = true, rasterize = 5)
    hspan!(ax, μlims[1], 0; color = c_ins)
    hlines!(ax, 1; color = :black, linestyle = :dash, linewidth = lw_guide)
    text!(ax, 1.49, 1.0; text = L"\mu_\mathrm{bulk}", align = (:right, :bottom), fontsize = fs_tick)

    Φ1, Φ2 = 0.65, 0.88
    yts, ytop = Yμ(μts), Yμ(μtop)
    skin = (0, yts, c_skin, 7)
    trajectory!(ax, Φ1, [(μlims[1], 0, c_insline, 4), skin, (yts, 1, c_topo, 4)])
    trajectory!(ax, Φ2, [(μlims[1], 0, c_insline, 4), skin, (yts, ytop, c_topo, 4), (ytop, 1, :black, 4)])
    ticks_on_trajectory!(ax, Φ2, μz_full; Y = Yμ, side = 1, valigns = (:center, :center, :bottom))
    ticks_on_trajectory!(ax, Φ1, μz_full; Y = Yμ, labels = (nothing, nothing, nothing))
    text!(ax, 1.2, 0.18; text = "Trivial skin", color = c_skin, font = :bold,
        fontsize = fs_label, align = (:center, :center))

    xlims!(ax, 0.5, 1.5)
    ax.xticks = ([0.5, Φ1, Φ2, 1.5], ["0.5", L"\Phi^{(1)}", L"\Phi^{(2)}", "1.5"])
    ax.xlabel = L"\Phi/\Phi_0"
    ax.yticks = ([yts], [L"\mu^\mathrm{ts}"])
    ax.yticklabelcolor = c_skin
    ax.ytickcolor = c_skin
end

function filling!(ax)
    # Schematic of paper Fig. 4(b): m_r = 1 band, k_z = 0, Φ = Φ0/2, realistic SOC
    fR(x) = 0.5 * (x - 1)^2 + 0.5
    fL(x) = 0.5 * (x + 1)^2 + 0.5
    xs = range(-2.1, 2.1, length = 200)
    xS = collect(range(-2, 2, length = 10))
    x0 = minimum(abs, xS)                  # the m_J = 0 pair sits where both branches cross
    μts = fR(x0)
    Ebottom = 0.5                          # band bottom: filling (and the skin) starts here
    ylo, yhi = 0.3, 1.15

    hspan!(ax, Ebottom, μts; color = c_skin_tint)
    hlines!(ax, μts; color = c_skin, linewidth = lw_data)
    text!(ax, 0, Ebottom - 0.03; text = "Trivial skin", color = c_skin, font = :bold, fontsize = fs_tick,
        align = (:center, :top))

    for (f, xJ) in ((fR, x0), (fL, -x0))
        lines!(ax, xs, f.(xs); color = c_grey, linewidth = lw_data)
        others = filter(x -> x != xJ && f(x) < yhi, xS)
        scatter!(ax, others, f.(others); color = :white, strokecolor = c_grey, strokewidth = 2, markersize = 16)
        scatter!(ax, [xJ], [f(xJ)]; color = c_topo, markersize = 22)
    end
    text!(ax, 0.45, μts + 0.03; text = rich(rich("m"; font = :italic), subscript("J"; font = :italic), " = 0"),
        color = c_topo, fontsize = fs_tick, align = (:left, :bottom))

    xlims!(ax, -2.1, 2.1)
    ylims!(ax, ylo, yhi)
    ax.xlabel = rich(rich("m"; font = :italic), subscript("L"; font = :italic))
    ax.ylabel = rich("E"; font = :italic)
    hidexdecorations!(ax; label = false)
    ax.yticks = ([μts], [L"\mu^\mathrm{ts}"])
    ax.yticklabelcolor = c_skin
    ax.ytickcolor = c_skin
end

function fig2()
    W, H = 373, 150
    fig = Figure(size = (W * mm, H * mm), figure_padding = 4mm, fontsize = fs_tick,
        backgroundcolor = :white)
    axP = Axis(fig[1, 1]; axis_style..., title = "Partial shell", titlesize = fs_title, titlefont = :regular)
    pd_partial!(axP)
    axF = Axis(fig[1, 2]; axis_style..., title = "Full shell", titlesize = fs_title, titlefont = :regular)
    pd_full!(axF)
    axB = Axis(fig[1, 3]; axis_style..., title = rich(rich("m"; font = :italic), subscript("J"; font = :italic), " = 0 threshold"), titlesize = fs_title, titlefont = :regular)
    filling!(axB)

    linkyaxes!(axP, axF)
    ylims!(axP, μlims...)

    for (c, w) in enumerate([0.37, 0.37, 0.26])
        colsize!(fig.layout, c, Auto(w))
    end
    colgap!(fig.layout, 8mm)
    return fig
end

## ---------------------------------------------------------------------------
## Render
## ---------------------------------------------------------------------------
function render(fig, name)
    save(joinpath(outdir, "$(name).pdf"), fig; pt_per_unit = 1)
    save(joinpath(outdir, "$(name)_preview.png"), fig; px_per_unit = 150 / 72)
end

if abspath(PROGRAM_FILE) == @__FILE__
    render(hero(; verdict = true), "hero_A")
    render(hero(; verdict = false), "hero_B")
    render(fig2(), "fig2")
end
