function dos_test(; pref = log(100))
    basepath = "data/DOS_chi"
    name = "base_fs_testing"
    key = "Majo"

    path = "$(basepath)/$(name).jld2"
    @load path res
    @unpack DOS, system = res
    @unpack χrng, ωrng = system.calc_params  
    Δ0 = system.params_wire.Δ0 |> real

    Ns = round.(Int, floor.(pref.*χrng./5)) .+ 1


    iω = findmin(abs.(ωrng .+ 0.05*0.23))[2]
    ωrng = ωrng[iω:end]

    ωrng = real.(ωrng)
    ωrng = vcat(ωrng, -reverse(ωrng)[2:end])

    DOS = DOS[key][:, iω:end]

    DOS0 = DOS[:, end]

    DOS = cat(DOS, reverse(DOS, dims = 2)[:, 2:end], dims = 2)


    fig = Figure()

    xlabel = L"$\chi$ (nm)"
    
    ylabel = L"$\omega / \Delta_0$"

    xticks = ([1, 10^1, 10^2, 10^3], [L"1", L"10", L"100", L"1000"])

    ax = Axis(fig[1, 1]; xlabel, ylabel, xticks, xscale = log10)
    hmap = heatmap!(ax, χrng, ωrng ./ Δ0, DOS; colormap = :thermal, rasterize = 5,  colorrange = (0, 1e-2))
    vlines!(ax, 70/k1; color = :lightgreen, linewidth = 3, linestyle = :dash)
    hidexdecorations!(ax; ticks = false)

    Colorbar(fig[1, 2], hmap;)

    ax = Axis(fig[2, 1]; xlabel, ylabel = L"$$ DOS", xticks, xscale = log10, yscale = log10 )

    scatter!(ax, χrng, DOS0)

    xlims!(ax, first(χrng), last(χrng))
    vlines!(ax, 70/k1; color = :black, linewidth = 3, linestyle = :dash)
    #ylims!(ax, 1, 1e5)
    fig
end

# fig = dos_test()
# fig