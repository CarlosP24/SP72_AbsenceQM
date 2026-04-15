
function figure_skin(; color0 = :turquoise, color1 = :coral)
    fig = Figure(size = (600, 300), fontsize = 20)

    ax = Axis(fig[1:2, 2]; alignmode = Mixed(bottom = -32))
    plot_µα(ax, "base_fs_alphazoom")
    text!(ax, 6.5, 80; text = L"m_r = 0", color = :black, align = (:center, :center), fontsize = 16)
    text!(ax, 30, 80; text = L"m_r = 1", color = :black, align = (:center, :center), fontsize = 16)

    vlines!(ax, [1]; color = :purple, linewidth = 1)
    xlims!(ax, -5, 35)
    ax.xticks = 0:10:30

    vlines!(ax, [21.9]; color = :navyblue, linewidth = 1)


    text!(ax, 2, 10; text = L"\mu_{m_r = 0}^\text{ts}", color = :purple)
    text!(ax, 22.5, 10; text = L"\mu_{m_r = 1}^\text{ts}", color = :navyblue)

    ins = MarkerElement(marker = :rect, color = (:gray, 0.2), strokecolor = :black, strokewidth = 1.5, markersize = 16)
    triv = MarkerElement(marker = :rect, color = :white, strokecolor = :black, strokewidth = 1.5, markersize = 16)
    topo = MarkerElement(marker = :rect, color = :red, strokecolor = :black, strokewidth = 1.5,  markersize = 16)
    Legend(fig[1, 2, Top()], [ins, triv, topo], ["Ins", "Triv", "Topo"], framevisible = false, orientation = :horizontal, labelsize = 14)


    fR0(x) = 0.5*(x - 1)^2
    fL0(x) = 0.5*(x + 1)^2

    fR0c(x) = let y = fR0(x); y < 0.5 ? y : NaN; end
    fL0c(x) = let y = fL0(x); y < 0.5 ? y : NaN; end

    fR1(x) = fR0(x) + 0.5
    fL1(x) = 0.5*(x + 1)^2 + 0.5

    xrng = range(-2.1, 2.1, length = 100)
    xrngS = range(-2, 2, length = 10)

    scatter_style = (markersize = 8, strokewidth = 1)

    center = (first(xrngS) + last(xrngS)) / 2
    xrng_collected = collect(xrngS)
    sorted_by_distance = sort(xrng_collected, by = x -> abs(x - center))
    xC = sorted_by_distance[1:2]


    ax = Axis(fig[1, 1])
    xlims!(ax, -2.1, 2.1)
    ylims!(ax, -0.1, 0.5)

    μ0 = 0.3
    hlines!(ax, μ0; color = :purple)

    lines!(ax, xrng, fR0.(xrng); color = color0, linewidth = 2, alpha = 0.1)
    lines!(ax, xrng, fL0.(xrng); color = color0, linewidth = 2, alpha = 0.1)
    lines!(ax, xrng, fR0c.(xrng); color = color0, linewidth = 2, label = L"m_r = 0")
    lines!(ax, xrng, fL0c.(xrng); color = color0, linewidth = 2)

    scatter!(ax, xrngS, fR0c.(xrngS); color = :white, strokecolor = color0, scatter_style...)
    scatter!(ax, xrngS, fL0c.(xrngS); color = :white, strokecolor = color0, scatter_style...)

    scatter!(ax, xC, fR0c.(xC); color = :red, strokecolor = color0, strokewidth = 2, markersize = 10)
    scatter!(ax, xC, fL0c.(xC); color = :red, strokecolor = color0, strokewidth = 2, markersize = 10)

    text!(ax, 0, 0.05; text = "Trivial\nskin", color = :black, align = (:center, :center), fontsize = 16)
    

    hidexdecorations!(ax, grid = false, ticks = false)
    
    ax.xticks = xrngS


    ax.yticks = ([0, 0.30], [L"0", L"\mu_{m_r = 0}^\text{ts}"])

    ax = Axis(fig[2, 1])
    xlims!(ax, -2.1, 2.1)
    ylims!(ax, -0.1, 1.1)

    hlines!(ax, 0.8; color = :navyblue)


    lines!(ax, xrng, fR0.(xrng); color = color0, linewidth = 2, alpha = 0.3)
    lines!(ax, xrng, fL0.(xrng); color = color0, linewidth = 2, alpha = 0.3)


    scatter!(ax, xrngS, fR0c.(xrngS); color = :white, strokecolor = color0, scatter_style...)
    scatter!(ax, xrngS, fL0c.(xrngS); color = :white, strokecolor = color0, scatter_style...)

    lines!(ax, xrng, fR1.(xrng); color = color1, linewidth = 2, label = L"m_r = 1")
    lines!(ax, xrng, fL1.(xrng); color = color1, linewidth = 2)

    scatter!(ax, xrngS, fR1.(xrngS); color = :white, strokecolor = color1, scatter_style...)
    scatter!(ax, xrngS, fL1.(xrngS); color = :white, strokecolor = color1, scatter_style...)

    scatter!(ax, xC, fR1.(xC); color = :red, strokecolor = color1, strokewidth = 2, markersize = 10)
    scatter!(ax, xC, fL1.(xC); color = :red, strokecolor = color1, strokewidth = 2, markersize = 10)

    text!(ax, 0, 0.2; text = "Trivial\nskin", color = :black, align = (:center, :center), fontsize = 16)

    ax.xticks = xrngS


    ax.yticks = ([0, 0.8], [L"0", L"\mu_{m_r = 1}^\text{ts}"])
    ax.xlabel = L"m_L \in \mathbb{Z}"
    hidexdecorations!(ax, grid = false, ticks = false, label = false)

    mr0 = LineElement( color = color0)
    mr1 = LineElement( color = color1)
    Legend(fig[1, 1, Top()], [mr0, mr1], [L"m_r = 0", L"m_r = 1"], framevisible = false, orientation = :horizontal, labelsize = 14)

    rowgap!(fig.layout, -10)

    style = (font = "CMU Serif Bold", fontsize   = 20)

    Label(fig[1, 1, TopLeft()], "a"; padding = (-20, 0, -30, 0), style...)
    Label(fig[2, 1, TopLeft()], "b"; padding = (-20, 0, -10, 0), style...)
    Label(fig[1, 2, TopLeft()], "c"; padding = (-50, 0, -30, 0), style...)

    return fig
end

fig = figure_skin()
save("plots/figures/Fig4.pdf", fig)
fig