function plot_wf(ax, name::String; key = "Majo", basepath = "data/wfs", color_majo = :blue, color_quasi = :red, quasi = true)
    path = "$(basepath)/$(name).jld2"
    @load path res
    @unpack Psis = res
    (Ψ2L, Ψ2R) = Psis[key]
    lines!(ax, range(0, 1, length(Ψ2L)), Ψ2L ./ maximum(Ψ2L); color = color_majo, linewidth = 2)
    quasi && lines!(ax, range(0, 1, length(Ψ2R)), Ψ2R ./ maximum(Ψ2R); color = color_quasi, linewidth = 2)

    L = length(Ψ2L)
    #xlims!(ax, 1, L/10)
end

# fig = Figure() 
# ax = Axis(fig[1, 1]) 
# plot_wf(ax, "base_partial";  key = "Majo")
# #xlims!(ax, 1, 200)
# fig