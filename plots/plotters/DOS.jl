function plot_DOS(ax, name::String; labels = true, basepath = "data/DOS", color_loop = [:lightgreen, :lightblue],  kw...)
    path = "$(basepath)/$(name).jld2"
    @load path res
    @unpack DOS, system = res
    @unpack Φrng_DOS, ωrng = system.calc_params

    ωrng = real.(ωrng)
    ωrng = vcat(ωrng, -reverse(ωrng)[2:end])

    DOS = sum(values(DOS))

    DOS = cat(DOS, reverse(DOS, dims = 2)[:, 2:end], dims = 2)

    heatmap!(ax, Φrng_DOS, ωrng, DOS; colormap = :thermal, colorrange = (0, 1), rasterize = 5, kw...)
    ax.ylabel = L"$\omega / \Delta_0$"
    
    if labels
        Φs = [0.7, 0.9]
        vlines!(ax, Φs, ymin = 0.9, color = color_loop, linewidth = 4 )
        return Φs
    end
end

function plot_TT(ax, name::String; basepath = "data/PD_flux", kw...)
    path = "$(basepath)/$(name).jld2"
    @load path res
    @unpack PD, system = res
    @unpack Φrng_PD = system.calc_params

    idx = findall(PD[1:end-1] .!= PD[2:end]) 
    i = isempty(idx) ? nothing : idx[1]

    vlines!(ax, Φrng_PD[i]; color = :white, linestyle = :dash, linewidth = 1, kw...)
end

function plot_DOS_B(ax, name::String; basepath = "data/DOS", Bc = 2, color_loop = [:lightgreen, :lightblue],  kw...)
    path = "$(basepath)/$(name).jld2"
    @load path res
    @unpack DOS, system = res
    @unpack Brng, ωrng = system.calc_params

    ωrng = real.(ωrng)
    ωrng = vcat(ωrng, -reverse(ωrng)[2:end])
    
    DOS = cat(DOS, reverse(DOS, dims = 2)[:, 2:end], dims = 2)
    heatmap!(ax, Brng ./ Bc, ωrng, DOS; colormap = :thermal, colorrange = (0, 1), rasterize = 5, kw...)
    ax.ylabel = L"$\omega / \Delta_0$"

    Bs = [1.5 * 2, 0.9 * 2]
    vlines!(ax, Bs ./Bc, ymin = 0.9, color = color_loop, linewidth = 4)

    return Bs ./Bc
end

# fig = Figure()
# ax = Axis(fig[1, 1])
# plot_DOS(ax, "base_fs")
# plot_TT(ax, "base_fs")
# fig