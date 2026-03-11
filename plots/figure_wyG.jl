function figure_wyG()
    fig = Figure(resolution = (600, 800), fontsize = 20)
    triv = MarkerElement(marker = :rect, color = :white, strokecolor = :black, strokewidth = 1.5, markersize = 16)
    topo = MarkerElement(marker = :rect, color = :red, markersize = 16)



    # Partial Shell
    # Sketch
    figSketch = fig[1:2, 1] = GridLayout()

    # Phase Diagram
    ax = Axis(fig[1, 2])
    plot_µB(ax, "base_partial")
    ylims!(ax, 0, 2)
    xlims!(ax, 0, 2)
    hidexdecorations!(ax, ticks = false, grid = false)
    ax.xticks = [0, 1, 2]
    ax.yticks = [0, 1, 2]
    ax.ylabel = L"$\mu / V_\text{Z}^\text{c}$"

    vlines!(ax, [1]; color = :orange, linestyle = :dash, linewidth = 2)
    axislegend(ax, [triv, topo], ["Triv", "Topo"], position = (0, 2.5), framevisible = false, orientation = :vertical, labelsize = 14)

    # DOS vs B
    ax = Axis(fig[2, 2])
    plot_DOS_B(ax, "base_partial")
    xlims!(ax, 0, 2)
    ax.xticks = ([0, 1, 2], [L"0", L"$V_\text{Z}^\text{c}$", L"$2V_\text{Z}^\text{c}$"])
    ax.yticks = ([-0.23, 0, 0.23], [L"-\Delta_0", L"0", L"\Delta_0"])
    ax.ylabelpadding = -15
    vlines!(ax, [1]; color = :orange, linestyle = :dash, linewidth = 2)

    # Full Shell
    # Sketch
    figSketch = fig[3:4, 1] = GridLayout()

    # Full flux DOS
    figDOS = fig[5, 1] = GridLayout()
    ax = Axis(figDOS[2, 1])
    plot_DOS(ax, "base_fs")
    plot_TT(ax, "base_fs")
    ax.xlabel = L"$\Phi/\Phi_0$"
    ax.yticks = ([-0.23, 0, 0.23], [L"-\Delta_0", L"0", L"\Delta_0"])
    ax.ylabelpadding = -15
    Colorbar(figDOS[1, 1]; colormap = :thermal, label = L"$$ DOS (arb. units)", ticks = [0, 1], limits = [0, 1], vertical = false, labelpadding = -25)
    rowgap!(figDOS, 1, 5)

    # Phase Diagram µ vs α
    ax = Axis(fig[3, 2])
    plot_µα(ax, "base_fs")
    ax.xticks = (0:10:60, ["0", "10", "", "", "", "50", "60"])
    ax.xlabelpadding = -20
    ax.yticks = 0:25:50
    ax.ylabelsize = 14
    scatter!(ax, [22.8], [7]; color = :navyblue)
    text!(ax, 14, 45; text = L"m_r = 1", color = :black, align = (:center, :center), fontsize = 16)
    text!(ax, 37.5, 35; text = L"m_r = 2", color = :white, rotation = π/2, align = (:center, :center), fontsize = 16)
    text!(ax, 55, 35; text = L"m_r = 3", color = :white, rotation = π/2, align = (:center, :center), fontsize = 16)


    #axislegend(ax, [triv, topo], ["Triv", "Topo"], position = :lb, framevisible = false, orientation = :vertical, labelsize = 14)


    # Phase Diagram µ vs Φ
    ax = Axis(fig[4, 2])
    plot_μΦ(ax, "base_fs_zoom")
    ax.xticks = [0.501, 1, 1.499]
    ax.yticks = ([21, 22, 23, 24], ["0", "22", "23", "24"])
    ax.ylabelsize = 16
    hidexdecorations!(ax, ticks = false, grid = false)
    hlines!(ax, [22.8]; color = :navyblue, linestyle = :dash)
    plot_TT(ax, "base_fs"; linewidth = 2, color = :orange)

    # DOS vs Φ, zoom
    ax = Axis(fig[5, 2])
    plot_DOS(ax, "base_fs_zoom"; colorrange = (9e-2, 5e-1))
    plot_TT(ax, "base_fs"; linewidth = 2, color = :orange)
    ylims!(ax, -0.026, 0.026)
    xlims!(ax, 0.501, 1.499)
    ax.xticks = ([0.501, 1, 1.499], ["0.5", "1", "1.5"])
    ax.xlabel = L"$\Phi/\Phi_0$"
    ax.yticks = ([-0.023, 0, 0.023], [L"-\frac{\Delta_0}{10}", L"0", L"\frac{\Delta_0}{10}"])
    ax.ylabelpadding = -25

    rowsize!(fig.layout, 1, Relative(0.12))
    rowsize!(fig.layout, 2, Relative(0.22))
    rowsize!(fig.layout, 3, Relative(0.18))
    rowsize!(fig.layout, 4, Relative(0.18))

    rowgap!(fig.layout, 1, 5)
    rowgap!(fig.layout, 2, -5)
    rowgap!(fig.layout, 3, -5)
    rowgap!(fig.layout, 4, -15)

    style = (font = "CMU Serif Bold", fontsize   = 20)

    Label(fig[1, 1, TopLeft()], "a"; padding = (-20, 0, -10, 0), style...)
    Label(fig[2, 1, TopLeft()], "b"; padding = (-20, 0, -30, 0), style...)

    Label(fig[1, 2, TopLeft()], "c"; padding = (-40, 0, -10, 0), style...)
    Label(fig[2, 2, TopLeft()], "d"; padding = (-40, 0, -30, 0), style...)

    Label(fig[3, 1, TopLeft()], "e"; padding = (-20, 0, -30, 0), style...)
    Label(fig[4, 1, TopLeft()], "f"; padding = (-20, 0, -10, 0), style...)
    Label(fig[5, 1, TopLeft()], "g"; padding = (-20, 0, -10, 0), style...)

    Label(fig[3, 2, TopLeft()], "h"; padding = (-40, 0, -10, 0), style...)
    Label(fig[4, 2, TopLeft()], "i"; padding = (-40, 0, -10, 0), style...)
    Label(fig[5, 2, TopLeft()], "j"; padding = (-40, 0, -10, 0), style...)

    return fig
end

fig = figure_wyG()
save("plots/figures/figure_wyG.pdf", fig)
fig