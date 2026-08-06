
function plot_wf_test(ax, name::String; key = "Majo", basepath = "data/wfs", color_majo = :blue, color_quasi = :red, quasi = true)
    path = "$(basepath)/$(name).jld2"
    @load path res
    @unpack Psis = res
    (Ψ2L, Ψ2R) = Psis[key]
    lines!(ax, range(0, 1, length(Ψ2L)), Ψ2L ; color = color_majo, linewidth = 2)
    quasi && lines!(ax, range(0, 1, length(Ψ2R)), Ψ2R; color = color_quasi, linewidth = 2)

    L = length(Ψ2L)
    #xlims!(ax, 1, L/10)
end


# plot_wf_test(ax, "base_fs_fdos";  key = "QMajo", quasi = true,)
# xlims!(ax, 0, 1)
# fig


##

function plot_DOS_test(ax, name::String;     basepath = "data/DOS")
    path = "$(basepath)/$(name).jld2"
    @load path res
    @unpack DOS, system = res
    @unpack Φrng_DOS, ωrng = system.calc_params

    DOS = DOS[0][:, 1]

    lines!(ax, Φrng_DOS, DOS; color = :blue, linewidth = 2)
end

# fig = Figure()
# ax = Axis(fig[1, 1])
# plot_DOS_test(ax, "base_fs_fdos";)
# plot_TT(ax, "base_fs"; color = :black, linewidth = 4)
# fig