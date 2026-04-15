function mbar!(ax, p1, p2; color = :white, linewidth = 2)
    arrows2d!(ax, [p1[1]], [p1[2]], [p2[1]], [p2[2]]; color, argmode = :endpoint, tip = Point2f[(0, -0.3), (0, 0.3), (0.5, 0.3), (0.5, -0.3)], tail = Point2f[(1, -0.3), (1, 0.3), (0.5, 0.3), (0.5, -0.3)], taillength = 4, tiplength = 4, shaftwidth = linewidth)
end



function figure_wyG(;)
    fig = Figure(size = (600, 900), fontsize = 20)
    
    ins = MarkerElement(marker = :rect, color = (:gray, 0.2), strokecolor = :black, strokewidth = 1.5, markersize = 16)
    triv = MarkerElement(marker = :rect, color = :white, strokecolor = :black, strokewidth = 1.5, markersize = 16)
    topo = MarkerElement(marker = :rect, color = :red, strokecolor = :black, strokewidth = 1.5,  markersize = 16)

    # Partial Shell
    # Sketch
    sketch_partial(fig[1:2, 1])
    # Phase Diagram
    color_loop = [:lightgreen, :lightblue]
    axP = Axis(fig[1, 2])
    plot_µB(axP, "base_partial")
    hlines!(axP, [1]; color = :black, linestyle = :dash, linewidth = 2)
    ylims!(axP, -2, 2)
    xlims!(axP, 0, 2)
    hidexdecorations!(axP, ticks = false, grid = false)
    axP.yticks = [-2, 0, 2]
    axP.ylabel = L"$\mu / V_\text{Z}^\text{c}$"

    vlines!(axP, [1]; color = :orange, linestyle = :dash, linewidth = 2)

    ax = Axis(fig[1, 2]; yaxisposition = :right)
    ylims!(ax, -2, 2)
    ax.yticks = ([1], [""])
    ax.yticklabelcolor = :black
    hidespines!(ax)
    hidexdecorations!(ax)
    text!(axP, 1.8, 1.5; text = L"\mu_\text{bulk}", color = :black, align = (:center, :center))

    Legend(fig[1, 2, Top()], [ins, triv, topo], ["Ins", "Triv", "Topo"], framevisible = false, orientation = :horizontal, labelsize = 14)


    # DOS vs B
    ax = Axis(fig[2, 2])
    Bs = plot_DOS_B(ax, "base_partial"; colorrange = (0, 4e-1), color_loop )
    xlims!(ax, 0, 2)
    ax.xticks = ([0,  1, 2], [L"0", L"$V_\text{Z}^\text{c}$", L"$V_\text{Z}$"])
    ax.yticks = ([-0.23, 0, 0.23], ["-1", "0", "1"])
    vlines!(ax, [1]; color = :orange, linestyle = :dash, linewidth = 2)

    text!(ax, 1.5, 0.07; text = "MZM", color = :white, align = (:center, :center), fontsize = 16)

    mbar!(ax, [1, 0.03], [2, 0.03]; color = :white, linewidth = 2)

    text!(ax, 0.9, -0.09; text = "Q-MZM", color = :white, align = (:center, :center), fontsize = 16)
    mbar!(ax, [0.7, -0.04], [1.0, -0.04]; color = :white, linewidth = 2)

    axP.xticks = vcat([0, 1, 2], Bs)
    arrows2d!(axP, Bs, [-2, -2], Bs, [1, 1]; color = color_loop, argmode = :endpoint, tiplength = 10, tipwidth = 10)

    ax = Axis(fig[2, 2]; xaxisposition = :top)
    xlims!(ax, 0, 2)
    ax.xticks = (Bs, [L"V_\text{Z}^{(1)}", L"V_\text{Z}^{(2)}"])
    hidespines!(ax)
    hideydecorations!(ax)
    hidexdecorations!(ax, ticks = false, ticklabels = false)

    Colorbar(fig[2, 3], colormap = :thermal, limits = (0, 1), ticks = [0, 1], label = L"$$ DOS (arb.  units)", labelpadding = -15, labelsize = 12)

    ax = Axis(fig[1:2, 1:3], alignmode = Mixed(bottom = -70, left = -30, right =    0))
    xlims!(ax, 0, 1)
    ylims!(ax, 0, 1)
    hlines!(ax, 0.1; color = :black, linewidth = 0.5)
    hidedecorations!(ax)
    hidespines!(ax)
    
    # Full Shell
    # Sketch
    sketch_FS(fig[3:4, 1])
    # Full flux DOS
    ax = Axis(fig[5, 1])
    plot_DOS(ax, "base_fs"; labels = false)
    ax.xlabel = L"$\Phi/\Phi_0$"
    ax.xticks = 0:0.5:2.5
    ax.yticks = ([-0.23, 0, 0.23], ["-1", "0", "1"]) 

    # Phase Diagram µ vs α
    ax = Axis(fig[3, 2])
    plot_µα(ax, "base_fs")
    ax.xticks = (0:10:60, ["0", "10", "", "", "", "50", "60"])
    ax.xlabelpadding = -20
    ax.yticks = 0:25:50
    ax.ylabelsize = 16
    ax.xlabelsize = 16
    xlims!(ax, -5, 60)
    scatter!(ax, [22.8], [7]; color = :navyblue)
    text!(ax, 14, 45; text = L"m_r = 1", color = :black, align = (:center, :center), fontsize = 16)
    text!(ax, 37.5, 35; text = L"m_r = 2", color = :white, rotation = π/2, align = (:center, :center), fontsize = 16)
    text!(ax, 55, 35; text = L"m_r = 3", color = :white, rotation = π/2, align = (:center, :center), fontsize = 16)

    text!(ax, 10, 25; text = "Trivial\nskin", align = (:center, :center), fontsize = 16)

    #axislegend(ax, [triv, topo], ["Triv", "Topo"], position = :lb, framevisible = false, orientation = :vertical, labelsize = 14)

    # Phase Diagram µ vs Φ
    color_loop = [:darkgreen, :darkblue]
    axP = Axis(fig[4, 2])
    plot_μΦ(axP, "base_fs_zoom")

    ylims!(axP, 20.7, 23.5)    
    axP.xticks = [0.501, 1, 1.499]
    axP.yticks = ([21, 22, 23, 24], ["0", "22", "23", "24"])
    axP.ylabelsize = 16
    hidexdecorations!(axP, ticks = false, grid = false)
    hlines!(axP, [22.8]; color = :black, linestyle = :dash)
    plot_TT(axP, "base_fs"; linewidth = 2, color = :orange)

    text!(axP, 1.1, 21.5; text = "Trivial\nskin", align = (:center, :center), fontsize = 16)
    text!(axP, 1.4, 23.1; text = L"\mu_\text{bulk}", color = :black, align = (:center, :center),)

    break_axis = Axis(fig[4, 2], alignmode = Mixed(left = -22))
    xlims!(break_axis, 0, 1)
    ylims!(break_axis, 0, 1)

    vlines!(break_axis, [0.1]; color = :white)
    vlines!(break_axis, [0.1]; color = (:black, 0.7))
    band!(break_axis, [0.07, 0.13], [0.18, 0.20], [0.22, 0.24]; color = :white)
    lines!(break_axis, [0.07, 0.13], [0.18, 0.20]; color = :black)
    lines!(break_axis, [0.07, 0.13], [0.22, 0.24]; color = :black)

    hidedecorations!(break_axis)
    hidespines!(break_axis)

    hidespines!(axP, :l)

    ax = Axis(fig[4, 2]; yaxisposition = :right)
    ylims!(ax, 20.7, 23.5)
    ax.yticks = ([22.8], [""])
    ax.yticklabelcolor = :black
    hidespines!(ax)
    hidexdecorations!(ax)
    hideydecorations!(ax, ticks = false, ticklabels = false)

    # DOS vs Φ, zoom
    ax = Axis(fig[5, 2])
    Φs = plot_DOS(ax, "base_fs_zoom"; colorrange = (5e-2, 5e-1), color_loop)
    Φ = plot_TT(ax, "base_fs"; linewidth = 2, color = :orange)
    ylims!(ax, -0.026, 0.026)
    xlims!(ax, 0.501, 1.499)

    ax.xticks = ([0.501, Φ, 1, 1.499], ["0.5", L"\Phi^\text{c}", "1", "1.5"])
    ax.xlabel = L"$\Phi/\Phi_0$"
    ax.yticks = ([-0.023, 0, 0.023], ["-0.1", "0", "0.1"]) 
    ax.ylabelpadding = -15

    mbar!(ax, [0.5, 0.004], [0.84, 0.004]; color = :white, linewidth = 2)
    text!(ax, 0.65, 0.008; text = "MZM", color = :white, align = (:center, :center), fontsize = 16)

    mbar!(ax, [0.84, -0.004], [0.94, -0.004]; color = :white, linewidth = 2)
    text!(ax, 0.86, -0.009; text = "Q-MZM", color = :white, align = (:left, :center), fontsize = 16)

    ax = Axis(fig[5, 2]; xaxisposition = :top)
    hidespines!(ax)
    hidexdecorations!(ax, ticks = false, ticklabels = false)
    hideydecorations!(ax)
    xlims!(ax, 0.501, 1.499)
    ax.xticks = (Φs, [L"\Phi^{(1)}", L"\Phi^{(2)}"])

    axP.xticks = vcat([0, 1, 2], Φs)
    arrows2d!(axP, Φs, [0, 0], Φs, [22.8, 22.8]; color = color_loop, argmode = :endpoint, tiplength = 10, tipwidth = 10)

    Colorbar(fig[5, 3], colormap = :thermal, limits = (0, 1), ticks = [0, 1], label = L"$$ DOS (arb.  units)", labelpadding = -15, labelsize = 12)

    rowgap!(fig.layout, 1, 5)
    rowgap!(fig.layout, 2, 5)
    rowgap!(fig.layout, 3, 0)
    rowgap!(fig.layout, 4, 5)

    colgap!(fig.layout, 2, 1)

    style = (font = "CMU Serif Bold", fontsize   = 20)

    Label(fig[1, 1, TopLeft()], "a"; padding = (-20, 0, -30, 0), style...)
    Label(fig[1, 1, TopLeft()], "a1"; padding = (-20, 0, -180, 0), style...)
    Label(fig[1, 1, TopLeft()], "a2"; padding = (-20, 0, -410, 0), style...)

    Label(fig[1, 2, TopLeft()], "b"; padding = (-40, 0, -30, 0), style...)
    Label(fig[2, 2, TopLeft()], "c"; padding = (-40, 0, -30, 0), style...)

    Label(fig[3, 1, TopLeft()], "d"; padding = (-20, 0, -30, 0), style...)
    Label(fig[3, 1, TopLeft()], "d1"; padding = (-20, 0, -170, 0), style...)
    Label(fig[3, 1, TopLeft()], "d2"; padding = (-20, 0, -400, 0), style...)


    Label(fig[3, 2, TopLeft()], "e"; padding = (-40, 0, -10, 0), style...)
    Label(fig[4, 2, TopLeft()], "f"; padding = (-40, 0, -10, 0), style...)

    Label(fig[5, 1, TopLeft()], "g"; padding = (-20, 0, -30, 0), style...)
    Label(fig[5, 2, TopLeft()], "h"; padding = (-40, 0, -30, 0), style...)

    return fig
end 

fig = figure_wyG()
save("plots/figures/Fig1.pdf", fig)
fig