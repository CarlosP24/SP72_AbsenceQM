function plot_LDOS(ax, name::String, key::String; basepath = "data/LDOS", pref = 1, kw...)
    path = "$(basepath)/$(name).jld2"
    @load path res
    @unpack LDOS, system = res
    if LDOS === nothing
        LDOS = res.DOS
    end
    @unpack χrng, ωrng = system.calc_params  

    if system.params_wire isa Params
        Δ0 = system.params_wire.Δ0 |> real
    else
        Δ0 = system.params_wire.Δ0
    end

    ωrng = real.(ωrng)
    ωrng = vcat(ωrng, -reverse(ωrng)[2:end])

    LDOS = LDOS[key]

    LDOS = cat(LDOS, reverse(LDOS, dims = 2)[:, 2:end], dims = 2)
    heatmap!(ax, χrng, pref * ωrng ./ Δ0, LDOS; colormap = :thermal, rasterize = 5, kw...)

    ax.xscale = log10
    xlims!(ax, 1, maximum(χrng))
end

# fig = Figure()
# ax = Axis(fig[1, 1]; xlabel = L"$\chi$ (nm)", ylabel = L"$\omega$ (meV)")
# plot_LDOS(ax, "base_fs_zoom", "QMajo"; colorrange = (0, 3e-1))
# fig
