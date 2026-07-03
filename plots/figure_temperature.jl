function figure_temperature(; colorrangeM = (0, 0.07), colorrangeQ = (0, 0.005))
    fig = Figure(size = (600, 500), fontsize = 20)

    xlabel = L"$\chi$ (nm)"
    ylabel = L"$V$ ($\mu$V)"
    cbarlab = (label = L"$\frac{dI}{dV}$ (e^2/h)", labelpadding = -35, labelsize = 16)

    xticks = ([1, 10^1, 10^2, 10^3], [L"1", L"10", L"100", L"1000"])

    temp = "_lowT"

    ax = Axis(fig[1, 1]; xlabel, ylabel, xticks)
    mGM, MGM = plot_conductance(ax, "base_fs_szoom"*temp, "Majo"; colorrange = colorrangeM,)
    hidexdecorations!(ax; ticks = false)

    ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"])
    ylims!(ax, -0.026, 0.026)

    text!(ax, 350, 0.015; text = L"$T = 10$mK", color = :white, align = (:center, :center))
    text!(ax, 600, -0.015; text = L"\Phi=\Phi^{(1)}", color = :white, align = (:center, :center))

    Colorbar(fig[1, 2], colormap = :thermal, limits = colorrangeM, ticks = [colorrangeM[1], colorrangeM[2]]; cbarlab...)

    ax = Axis(fig[1, 3]; xlabel, ylabel, xticks)
    mGQ, MGQ = plot_conductance(ax, "base_fs_szoom"*temp, "QMajo";  colorrange = colorrangeQ)
    hideydecorations!(ax; ticks = false)
    hidexdecorations!(ax; ticks = false)

    ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"])
    ylims!(ax, -0.026, 0.026)

    text!(ax, 350, 0.015; text = L"$T = 10$mK", color = :white, align = (:center, :center))
    text!(ax, 600, -0.015; text = L"\Phi=\Phi^{(2)}", color = :white, align = (:center, :center))

    Colorbar(fig[1, 4], colormap = :thermal, limits = colorrangeQ, ticks = [colorrangeQ[1], colorrangeQ[2]]; cbarlab...)


    temp = "_midT"

    ax = Axis(fig[2, 1]; xlabel, ylabel, xticks)
    mGM, MGM = plot_conductance(ax, "base_fs_szoom"*temp, "Majo";colorrange = colorrangeM)
    hidexdecorations!(ax; ticks = false)

    ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"])
    ylims!(ax, -0.026, 0.026)

    text!(ax, 350, 0.015; text = L"$T = 25$mK", color = :white, align = (:center, :center))
    text!(ax, 600, -0.015; text = L"\Phi=\Phi^{(1)}", color = :white, align = (:center, :center))

    Colorbar(fig[2, 2], colormap = :thermal, limits = colorrangeM, ticks = [colorrangeM[1], colorrangeM[2]]; cbarlab... )

    
    ax = Axis(fig[2, 3]; xlabel, ylabel, xticks)
    mGQ, MGQ = plot_conductance(ax, "base_fs_szoom"*temp, "QMajo"; colorrange = colorrangeQ )
    hideydecorations!(ax; ticks = false)
    hidexdecorations!(ax; ticks = false)

    ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"])
    ylims!(ax, -0.026, 0.026)

    text!(ax, 350, 0.015; text = L"$T = 25$mK", color = :white, align = (:center, :center))
    text!(ax, 600, -0.015; text = L"\Phi=\Phi^{(2)}", color = :white, align = (:center, :center))

    Colorbar(fig[2, 4], colormap = :thermal, limits = colorrangeQ, ticks = [colorrangeQ[1], colorrangeQ[2]]; cbarlab... )
    

    temp = "_highT"

    ax = Axis(fig[3, 1]; xlabel, ylabel, xticks)
    mGM, MGM = plot_conductance(ax, "base_fs_szoom"*temp, "Majo"; colorrange = colorrangeM )

    ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"])
    ylims!(ax, -0.026, 0.026)

    text!(ax, 270, 0.015; text = L"$T = 100$mK", color = :white, align = (:center, :center))
    text!(ax, 600, -0.015; text = L"\Phi=\Phi^{(1)}", color = :white, align = (:center, :center))
    
    Colorbar(fig[3, 2], colormap = :thermal, limits = colorrangeM, ticks = [colorrangeM[1], colorrangeM[2]]; cbarlab... )


    ax = Axis(fig[3, 3]; xlabel, ylabel, xticks)
    mGQ, MGQ = plot_conductance(ax, "base_fs_szoom"*temp, "QMajo"; colorrange = colorrangeQ )
    hideydecorations!(ax; ticks = false)

    ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"])
    ylims!(ax, -0.026, 0.026)

    text!(ax, 270, 0.015; text = L"$T = 100$mK", color = :white, align = (:center, :center))
    text!(ax, 600, -0.015; text = L"\Phi=\Phi^{(2)}", color = :white, align = (:center, :center))

    Colorbar(fig[3, 4], colormap = :thermal, limits = colorrangeQ, ticks = [colorrangeQ[1], colorrangeQ[2]]; cbarlab... )

    Label(fig[1, 1, Top()], "MZM"; padding = (0, 0, 10, 0))
    Label(fig[1, 3, Top()], "Q-MZM"; padding = (0, 0, 10, 0) )


    style = (font = "CMU Serif Bold", fontsize   = 20)

    Label(fig[1, 1, TopLeft()], "a"; padding = (-40, 0, -20, 0), style...)
    Label(fig[1, 3, TopLeft()], "b"; padding = (-20, 0, -20, 0), style...)
    Label(fig[2, 1, TopLeft()], "c"; padding = (-40, 0, -20, 0), style...)
    Label(fig[2, 3, TopLeft()], "d"; padding = (-20, 0, -20, 0), style...)
    Label(fig[3, 1, TopLeft()], "e"; padding = (-40, 0, -20, 0), style...)
    Label(fig[3, 3, TopLeft()], "f"; padding = (-20, 0, -20, 0), style...)

    colgap!(fig.layout, 1, 5)
    colgap!(fig.layout, 2, 25)
    colgap!(fig.layout, 3, 5)

    return fig
end

fig = figure_temperature()
save("plots/figures/SFig_Temperature.pdf", fig)
fig