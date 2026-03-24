function plot_µα(ax, name::String; basepath = "data/PD_mu_alpha")
    path = "$(basepath)/$(name).jld2"
    @load path res
    @unpack PD, system = res
    @unpack αrng, µrng = system.calc_params
    band!(ax, [-10, 0], first(αrng), last(αrng); color = (:gray, 0.2))
    heatmap!(ax, µrng, αrng, PD; colormap = [(:red, 0.5), (:white, 0.5)], rasterize = 5)
    ax.xlabel = L"$\mu$ (meV)"
    ax.ylabel = L"$\langle \alpha \rangle$ (meVnm)"
end

# fig = Figure()
# ax = Axis(fig[1, 1])
# plot_µα(ax, "base_fs"; basepath = "data/PD_mu_alphaZ")
# fig
##
function plot_µαZ(ax, name::String; basepath = "data/PD_mu_alphaZ", basepath0 = "data/PD_mu_alpha")
    path = "$(basepath0)/$(name).jld2"
    @load path res
    @unpack PD, system = res
    @unpack αrng, µrng = system.calc_params
    heatmap!(ax, µrng, αrng, PD; colormap = [:orange, (:white, 0)])
    
    path = "$(basepath)/$(name).jld2"
    @load path res
    @unpack PD, system = res

    band!(ax, [-10, 0], first(αrng), last(αrng); color = (:gray, 0.2))
    heatmap!(ax, µrng, αrng, PD; colormap = [(:red, 0.5), (:white, 0.5)], rasterize = 5)
    ax.xlabel = L"$\mu$ (meV)"
    ax.ylabel = L"$\langle \alpha \rangle$ (meVnm)"


end

# fig = Figure(size = (600, 300), fontsize = 20)
# ax = Axis(fig[1, 1])
# plot_µαZ(ax, "base_fs"; basepath = "data/PD_mu_alphaZ")
# fig

# ##
# fig = Figure(size = (600, 300), fontsize = 20)
# ax = Axis(fig[1, 1])
# plot_µαZ(ax, "base_fs_hex"; basepath = "data/PD_mu_alphaZ")
# fig

##
function plot_μΦ(ax, name::String; basepath = "data/PD_mu_flux", μ0fake = 21)
    path = "$(basepath)/$(name).jld2"
    @load path res
    @unpack PD, system = res
    @unpack Φrng_PD, µrng = system.calc_params
    band!(ax, Φrng_PD, 0, μ0fake; color = (:gray, 0.2))
    heatmap!(ax, Φrng_PD, µrng, PD'; colormap = [(:red, 0.5), (:white, 0.5)], rasterize = 5)
    ax.ylabel = L"$\mu$ (meV)"
    ax.xlabel = L"$\Phi/\Phi_0$"
end

function plot_µB(ax, name::String; basepath = "data/PD_mu_B", Bc = 2)
    path = "$(basepath)/$(name).jld2"
    @load path res
    @unpack PD, system = res
    @unpack Brng, µrngP = system.calc_params
    band!(ax, Brng ./Bc, -2, 0; color = (:gray, 0.2))
    heatmap!(ax, Brng ./ Bc, µrngP ./ Bc, replace(PD', -1 => NaN); colormap = [:white], rasterize = 5)
    heatmap!(ax, Brng ./ Bc, µrngP ./ Bc, PD'; colormap = [(:white, 0.5), (:red, 0.5)], rasterize = 5)
    ax.ylabel = L"$\mu$ (meV)"
    ax.xlabel = L"$V_\text{Z}$ (meV)"
end

# fig = Figure()
# ax = Axis(fig[1, 1])
# plot_μΦ(ax, "base_fs")
# fig
##
# fig = Figure()
# ax = Axis(fig[1, 1]; )
# plot_μΦ(ax, "base_fs")

# xlims!(ax, 0, 1.5)
# ax.xticks = 0:0.5:1

# ylims!(ax, 21, 25)

# hlines!(ax, [22.8]; color = :navyblue, linestyle = :dash, linewidth = 1)

# ax = Axis(fig[1, 2],
# )
# plot_µα(ax, "base_fs")
# hideydecorations!(ax, grid = false)
# ax.xticks = 10:20:50
# ylims!(ax, 21, 25)

# vlines!(ax, [7]; color = :navyblue, linestyle = :dash, linewidth = 1)
# hlines!(ax, [22.8]; color = :navyblue, linestyle = :dash, linewidth = 1)

# colgap!(fig.layout, 1, 0)
# colsize!(fig.layout, 1, Relative(3/5))
# fig