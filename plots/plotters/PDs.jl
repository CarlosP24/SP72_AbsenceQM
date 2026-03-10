function plot_µα(ax, name::String; basepath = "data/PD_mu_alpha")
    path = "$(basepath)/$(name).jld2"
    @load path res
    @unpack PD, system = res
    @unpack αrng, µrng = system.calc_params
    heatmap!(ax, αrng, µrng, PD'; colormap = [:red, (:white, 0)])
    ax.ylabel = L"$\mu$ (meV)"
    ax.xlabel = L"$\langle \alpha \rangle$ (meVnm)"
end

# fig = Figure()
# ax = Axis(fig[1, 1])
# plot_muα(ax, "base_fs")
# fig

##
function plot_μΦ(ax, name::String; basepath = "data/PD_mu_flux")
    path = "$(basepath)/$(name).jld2"
    @load path res
    @unpack PD, system = res
    @unpack Φrng, µrng = system.calc_params
    heatmap!(ax, Φrng, µrng, PD'; colormap = [:red, (:white, 0)])
    ax.ylabel = L"$\mu$ (meV)"
    ax.xlabel = L"$\Phi/\Phi_0$"
end

# fig = Figure()
# ax = Axis(fig[1, 1])
# plot_μΦ(ax, "base_fs")
# fig
##
fig = Figure()
ax = Axis(fig[1, 1])
plot_μΦ(ax, "base_fs")

xlims!(ax, 0, 1.5)

ax.xticks = 0:0.5:1

# Create inset axis: same height as ax, 2/5 its width, right-aligned, y-axis on right
ax = Axis(fig[1, 2],
)
plot_µα(ax, "base_fs")
hideydecorations!(ax)
ax.xticks = 10:20:50

colgap!(fig.layout, 1, 0)
colsize!(fig.layout, 1, Relative(3/5))
fig