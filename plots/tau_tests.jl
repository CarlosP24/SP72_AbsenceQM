function tau_test(τ)
    fig = Figure(size = (600, 250), fontsize = 20)

    xlabel = L"$\chi$ (nm)"
    ylabel = L"$V$ ($\mu$V)"
    cbarlab = (label = L"$\frac{dI}{dV}$ (e^2/h)", labelsize = 16)

    xticks = ([1, 10^1, 10^2, 10^3], [L"1", L"10", L"100", L"1000"])

    ax = Axis(fig[1, 1]; xlabel, ylabel, xticks)
    mGM, MGM = plot_conductance(ax, "base_fs_tau="*τ, "Majo";)

    Colorbar(fig[1, 2], colormap = :thermal, limits = (0, MGM); cbarlab...)


    ax = Axis(fig[1, 3]; xlabel, ylabel, xticks)
    mGQ, MGQ = plot_conductance(ax, "base_fs_tau="*τ, "QMajo";)
    hideydecorations!(ax; ticks = false)

    Colorbar(fig[1, 4], colormap = :thermal, limits = (0, MGQ); cbarlab...)

    return fig
end

τ = "0.9"
fig = tau_test(τ)
save("tau_test_" * τ * ".pdf", fig)
fig

##
function cond_vs_tau(name::String, key::String; basepath = "data/Conductance_Tau")
    path = "$(basepath)/$(name).jld2"
    @load path res
    @unpack G, system = res
    @unpack τrng, ωrng = system.calc_params

    ωrng = real.(ωrng)
    ωrng = vcat(ωrng, -reverse(ωrng)[2:end])

    ωback = 0.005

    iω = findmin(abs.(ωrng .- ωback))[2]

    Cond = G[key]
    Cond0 = Cond[:, end]
  
    Cond = cat(Cond, reverse(Cond, dims = 2)[:, 2:end], dims = 2)
    Condback = Cond[:, iω]

    fig = Figure()
    ax = Axis(fig[1, 1]; xlabel = L"$\tau$", ylabel = L"$V$ ($\mu$V)")

    hmap = heatmap!(ax, τrng, ωrng, Cond; colormap = :thermal, colorscale = log10, rasterize = 5,)
    xlims!(ax, minimum(τrng), maximum(τrng))

    ax.xscale = log10

    hidexdecorations!(ax; ticks = false)

    vlines!(ax, 0.045; color = :white, linestyle = :dash)

    Colorbar(fig[1, 2], hmap; label = L"$\frac{dI}{dV}$ (e^2/h)", labelsize = 16)

    ax = Axis(fig[2, 1]; xlabel = L"$\tau$", ylabel = L"$\frac{dI}{dV}$ (e^2/h)")
    lines!(ax, τrng, Cond0; color = :blue, )

    hlines!(ax, [2]; color = :red, linestyle = :dash, linewidth = 2)
    xlims!(ax, minimum(τrng), maximum(τrng))

    ax.xscale = log10
    ax.yticks = [0, 2, 5, 10]
    vlines!(ax, [0.045]; color = :black, linestyle = :dash)


    return fig
end

fig = cond_vs_tau("base_partial_szoom_lowT", "Majo")
fig