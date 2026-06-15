function plot_conductance(ax, name::String, key::String; basepath = "data/Conductance", kw...)
    path = "$(basepath)/$(name).jld2"
    @load path res
    @unpack G, system = res
    @unpack χrng, ωrng = system.calc_params

    ωrng = real.(ωrng)
    ωrng = vcat(ωrng, -reverse(ωrng)[2:end])


    Cond = G[key]
    Cond = cat(Cond, reverse(Cond, dims = 2)[:, 2:end], dims = 2)

    heatmap!(ax, χrng, ωrng, Cond; colormap = :thermal, rasterize = 5, kw...)

    ax.xscale = log10
    xlims!(ax, 1, maximum(χrng))

    MG = maximum(Cond)
    mG = minimum(Cond)
    return mG, MG
end