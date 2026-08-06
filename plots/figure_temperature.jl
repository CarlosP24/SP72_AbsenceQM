function plot_panel(pos, temp, χ; T = 10, xlabel = L"$\Phi/\Phi_0$", ylabel = L"$V$ ($\mu$V)", colorrange = (0, 0.07))
    ax = Axis(pos; xlabel, ylabel)
    plot_conductance_Phi(ax, "base_fs_szoom"*temp, χ; colorrange, colorscale = Makie.pseudolog10)
    Φ = plot_TT(ax, "base_fs"; linewidth = 2, color = :orange)

    ax.xticks = ([0.501, Φ, 1, 1.499], ["0.5", L"\Phi^\text{c}", "1", "1.5"])
    ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"])
    ylims!(ax, -0.05, 0.05)

    text!(ax, 1.3, 0; text = L"$T = %$(T)$mK", color = :white, align = (:center, :center))

    return ax
end

function cbar(pos, colorrange; kw...)
    Colorbar(pos, colormap = :thermal, limits = colorrange, ticks = [colorrange[1], colorrange[2]]; label = L"$\frac{dI}{dV}$ (e^2/h)", labelpadding = -48, labelsize = 16, lowclip = to_colormap(:thermal) |> first, highclip = to_colormap(:thermal) |> last, kw...)
end

function figure_temperature(; χ = 10)
    fig = Figure(size = (600, 600), fontsize = 20)

    colorrange = (1e-4, 0.001)
    ax = plot_panel(fig[1, 1], "_lowT", χ; T = 10, colorrange)
    hidexdecorations!(ax; ticks = false)
    cbar(fig[1, 2], colorrange, limits = (1e-4, 1e-3), ticks = ([1e-4, 1e-3], [L"10^{-4}", L"10^{-3}"]), labelpadding = -25)

    colorrange = (5e-5, 2e-4)
    ax = plot_panel(fig[2, 1], "_midT", χ; T = 50, colorrange)
    hidexdecorations!(ax; ticks = false)
    cbar(fig[2, 2], colorrange, limits = (5e-5, 2e-4), ticks = ([5e-5, 2e-4], [L"5 \cdot 10^{-5}", L"2 \cdot 10^{-4}"]))

    colorrange = (5e-5, 2e-4)
    plot_panel(fig[3, 1], "_highT", χ; T = 100, colorrange )
    cbar(fig[3, 2], colorrange, limits = (5e-5, 2e-4), ticks = ([5e-5, 2e-4], [L"5 \cdot 10^{-5}", L"2 \cdot 10^{-4}"]))


    style = (font = "CMU Serif Bold", fontsize   = 20)

    Label(fig[1, 1, TopLeft()], "a"; padding = (-40, 0, -20, 0), style...)
    Label(fig[2, 1, TopLeft()], "b"; padding = (-40, 0, -20, 0), style...)
    Label(fig[3, 1, TopLeft()], "c"; padding = (-40, 0, -20, 0), style...)

    colgap!(fig.layout, 1, 5)
    return fig
end

# fig = figure_temperature()
# save("plots/figures/SFig_Temperature.pdf", fig)
# fig

