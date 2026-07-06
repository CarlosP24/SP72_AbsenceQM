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

fig = figure_temperature()
save("plots/figures/SFig_Temperature.pdf", fig)
fig

# function figure_temperature(; colorrangeM = (0, 0.07), colorrangeQ = (0, 0.005))
#     fig = Figure(size = (600, 500), fontsize = 20)

#     xlabel = L"$\chi$ (nm)"
#     ylabel = L"$V$ ($\mu$V)"
#     cbarlab = (label = L"$\frac{dI}{dV}$ (e^2/h)", labelpadding = -35, labelsize = 16)

#     xticks = ([1, 10^1, 10^2, 10^3], [L"1", L"10", L"100", L"1000"])

#     temp = "_lowT"

#     ax = Axis(fig[1, 1]; xlabel, ylabel, xticks)
#     mGM, MGM = plot_conductance(ax, "base_fs_szoom"*temp, "Majo"; colorrange = colorrangeM,)
#     hidexdecorations!(ax; ticks = false)

#     ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"])
#     ylims!(ax, -0.026, 0.026)

#     text!(ax, 350, 0.015; text = L"$T = 10$mK", color = :white, align = (:center, :center))
#     text!(ax, 600, -0.015; text = L"\Phi=\Phi^{(1)}", color = :white, align = (:center, :center))

#     Colorbar(fig[1, 2], colormap = :thermal, limits = colorrangeM, ticks = [colorrangeM[1], colorrangeM[2]]; cbarlab...)

#     ax = Axis(fig[1, 3]; xlabel, ylabel, xticks)
#     mGQ, MGQ = plot_conductance(ax, "base_fs_szoom"*temp, "QMajo";  colorrange = colorrangeQ)
#     hideydecorations!(ax; ticks = false)
#     hidexdecorations!(ax; ticks = false)

#     ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"])
#     ylims!(ax, -0.026, 0.026)

#     text!(ax, 350, 0.015; text = L"$T = 10$mK", color = :white, align = (:center, :center))
#     text!(ax, 600, -0.015; text = L"\Phi=\Phi^{(2)}", color = :white, align = (:center, :center))

#     Colorbar(fig[1, 4], colormap = :thermal, limits = colorrangeQ, ticks = [colorrangeQ[1], colorrangeQ[2]]; cbarlab...)


#     temp = "_midT"

#     ax = Axis(fig[2, 1]; xlabel, ylabel, xticks)
#     mGM, MGM = plot_conductance(ax, "base_fs_szoom"*temp, "Majo";colorrange = colorrangeM)
#     hidexdecorations!(ax; ticks = false)

#     ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"])
#     ylims!(ax, -0.026, 0.026)

#     text!(ax, 350, 0.015; text = L"$T = 25$mK", color = :white, align = (:center, :center))
#     text!(ax, 600, -0.015; text = L"\Phi=\Phi^{(1)}", color = :white, align = (:center, :center))

#     Colorbar(fig[2, 2], colormap = :thermal, limits = colorrangeM, ticks = [colorrangeM[1], colorrangeM[2]]; cbarlab... )

    
#     ax = Axis(fig[2, 3]; xlabel, ylabel, xticks)
#     mGQ, MGQ = plot_conductance(ax, "base_fs_szoom"*temp, "QMajo"; colorrange = colorrangeQ )
#     hideydecorations!(ax; ticks = false)
#     hidexdecorations!(ax; ticks = false)

#     ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"])
#     ylims!(ax, -0.026, 0.026)

#     text!(ax, 350, 0.015; text = L"$T = 25$mK", color = :white, align = (:center, :center))
#     text!(ax, 600, -0.015; text = L"\Phi=\Phi^{(2)}", color = :white, align = (:center, :center))

#     Colorbar(fig[2, 4], colormap = :thermal, limits = colorrangeQ, ticks = [colorrangeQ[1], colorrangeQ[2]]; cbarlab... )
    

#     temp = "_highT"

#     ax = Axis(fig[3, 1]; xlabel, ylabel, xticks)
#     mGM, MGM = plot_conductance(ax, "base_fs_szoom"*temp, "Majo"; colorrange = colorrangeM )

#     ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"])
#     ylims!(ax, -0.026, 0.026)

#     text!(ax, 270, 0.015; text = L"$T = 100$mK", color = :white, align = (:center, :center))
#     text!(ax, 600, -0.015; text = L"\Phi=\Phi^{(1)}", color = :white, align = (:center, :center))
    
#     Colorbar(fig[3, 2], colormap = :thermal, limits = colorrangeM, ticks = [colorrangeM[1], colorrangeM[2]]; cbarlab... )


#     ax = Axis(fig[3, 3]; xlabel, ylabel, xticks)
#     mGQ, MGQ = plot_conductance(ax, "base_fs_szoom"*temp, "QMajo"; colorrange = colorrangeQ )
#     hideydecorations!(ax; ticks = false)

#     ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"])
#     ylims!(ax, -0.026, 0.026)

#     text!(ax, 270, 0.015; text = L"$T = 100$mK", color = :white, align = (:center, :center))
#     text!(ax, 600, -0.015; text = L"\Phi=\Phi^{(2)}", color = :white, align = (:center, :center))

#     Colorbar(fig[3, 4], colormap = :thermal, limits = colorrangeQ, ticks = [colorrangeQ[1], colorrangeQ[2]]; cbarlab... )

#     Label(fig[1, 1, Top()], "MZM"; padding = (0, 0, 10, 0))
#     Label(fig[1, 3, Top()], "Q-MZM"; padding = (0, 0, 10, 0) )


#     style = (font = "CMU Serif Bold", fontsize   = 20)

#     Label(fig[1, 1, TopLeft()], "a"; padding = (-40, 0, -20, 0), style...)
#     Label(fig[1, 3, TopLeft()], "b"; padding = (-20, 0, -20, 0), style...)
#     Label(fig[2, 1, TopLeft()], "c"; padding = (-40, 0, -20, 0), style...)
#     Label(fig[2, 3, TopLeft()], "d"; padding = (-20, 0, -20, 0), style...)
#     Label(fig[3, 1, TopLeft()], "e"; padding = (-40, 0, -20, 0), style...)
#     Label(fig[3, 3, TopLeft()], "f"; padding = (-20, 0, -20, 0), style...)

#     colgap!(fig.layout, 1, 5)
#     colgap!(fig.layout, 2, 25)
#     colgap!(fig.layout, 3, 5)

#     return fig
# end

# fig = figure_temperature()
# save("plots/figures/SFig_Temperature.pdf", fig)
# fig