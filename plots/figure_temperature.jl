function figure_temperature()
    fig = Figure(size = (600, 400), fontsize = 20)

    xlabel = L"$\chi$ (nm)"
    ylabel = L"$V$ ($\mu$V)"

    temp = "_lowT"

    ax = Axis(fig[1, 1]; xlabel, ylabel)
    mGM, MGM = plot_conductance(ax, "base_fs_szoom"*temp, "Majo";)
    hidexdecorations!(ax; ticks = false)

    ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"])
    ylims!(ax, -0.026, 0.026)

    text!(ax, 170, 0.015; text = L"$T = 10$mK", color = :white, align = (:center, :center))
    text!(ax, 200, -0.015; text = L"\Phi=\Phi^{(1)}", color = :white, align = (:center, :center))
    
    ax = Axis(fig[1, 2]; xlabel, ylabel)
    mGQ, MGQ = plot_conductance(ax, "base_fs_szoom"*temp, "QMajo";  )
    hideydecorations!(ax; ticks = false)
    hidexdecorations!(ax; ticks = false)

    ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"])
    ylims!(ax, -0.026, 0.026)

    text!(ax, 170, 0.015; text = L"$T = 10$mK", color = :white, align = (:center, :center))
    text!(ax, 200, -0.015; text = L"\Phi=\Phi^{(2)}", color = :white, align = (:center, :center))

    Colorbar(fig[1, 3], colormap = :thermal, limits = (0, maximum([MGM, MGQ])), ticks = [0, 0.09],  label = L"$G$ (e^2/h)", labelpadding = -25)


    temp = "_highT"

    ax = Axis(fig[2, 1]; xlabel, ylabel)
    mGM, MGM = plot_conductance(ax, "base_fs_szoom"*temp, "Majo";)

    ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"])
    ylims!(ax, -0.026, 0.026)

    text!(ax, 150, 0.015; text = L"$T = 100$mK", color = :white, align = (:center, :center))
    text!(ax, 200, -0.015; text = L"\Phi=\Phi^{(1)}", color = :white, align = (:center, :center))
    
    ax = Axis(fig[2, 2]; xlabel, ylabel)
    mGQ, MGQ = plot_conductance(ax, "base_fs_szoom"*temp, "QMajo";  )
    hideydecorations!(ax; ticks = false)

    ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"])
    ylims!(ax, -0.026, 0.026)

    text!(ax, 150, 0.015; text = L"$T = 100$mK", color = :white, align = (:center, :center))
    text!(ax, 200, -0.015; text = L"\Phi=\Phi^{(2)}", color = :white, align = (:center, :center))

    Colorbar(fig[2, 3], colormap = :thermal, limits = (0, maximum([MGM, MGQ])), ticks = [0, 0.01], label = L"$G$ (e^2/h)", labelpadding = -34)
    
    Label(fig[1, 1, Top()], "MZM"; padding = (0, 0, 10, 0))
    Label(fig[1, 2, Top()], "Q-MZM"; padding = (0, 0, 10, 0) )


    style = (font = "CMU Serif Bold", fontsize   = 20)

    Label(fig[1, 1, TopLeft()], "a"; padding = (-40, 0, -20, 0), style...)
    Label(fig[1, 2, TopLeft()], "b"; padding = (-20, 0, -20, 0), style...)
    Label(fig[2, 1, TopLeft()], "c"; padding = (-40, 0, -20, 0), style...)
    Label(fig[2, 2, TopLeft()], "d"; padding = (-20, 0, -20, 0), style...)

    colgap!(fig.layout, 2, 5)
    rowgap!(fig.layout, 1, 5)
    return fig
end

fig = figure_temperature()
save("plots/figures/SFig_Temperature.pdf", fig)
fig