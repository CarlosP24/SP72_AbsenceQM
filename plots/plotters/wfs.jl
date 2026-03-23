function plot_wf(ax, name::String; key = "Majo", basepath = "data/wfs")
    path = "$(basepath)/$(name).jld2"
    @load path res
    @unpack Psis = res
    (Ψ2L, Ψ2R) = Psis[key]
    lines!(ax, Ψ2L; color = :blue, linewidth = 2)
    lines!(ax, Ψ2R; color = :red, linewidth = 2)

    L = length(Ψ2L)
    #xlims!(ax, 1, L/10)
end

fig = Figure() 
ax = Axis(fig[1, 1]) 
plot_wf(ax, "base_partial";  key = "QMajo")
#xlims!(ax, 1, 200)
fig