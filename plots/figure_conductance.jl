function figure_conductance(temp::String = "")
    fig = Figure(size = (600, 450), fontsize = 20)


    xlabel = L"$\chi$ (nm)"
    ylabel = L"$V$ ($\mu$V)"

    ax = Axis(fig[1, 1]; xlabel, ylabel)
    mGM, MGM = plot_conductance(ax, "base_fs_szoom"*temp, "Majo";)

    ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"])
    ylims!(ax, -0.026, 0.026)

    text!(ax, 200, 0.015; text = "MZM", color = :white, align = (:center, :center))
    text!(ax, 200, -0.015; text = L"\Phi=\Phi^{(1)}", color = :white, align = (:center, :center))
    
    ax = Axis(fig[1, 2]; xlabel, ylabel)
    mGQ, MGQ = plot_conductance(ax, "base_fs_szoom"*temp, "QMajo";  )
    hideydecorations!(ax; ticks = false)

    ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"])
    ylims!(ax, -0.026, 0.026)

    text!(ax, 200, 0.015; text = "Q-MZM", color = :white, align = (:center, :center))
    text!(ax, 200, -0.015; text = L"\Phi=\Phi^{(2)}", color = :white, align = (:center, :center))
    
    Colorbar(fig[1, 3], colormap = :thermal, limits = (0, maximum([MGM, MGQ])), ticks = [0, 2], label = L"$G$ (e^2/h)", labelpadding = -15)

    xlabel = L"$\Phi / \Phi_0$"
    ax = Axis(fig[2, 1]; xlabel, ylabel)
    mGM, MGM = plot_conductance_Phi(ax, "base_fs_szoom"*temp*"_Phis", 5; colorrange = (0, 0.6))
    ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"])
    ylims!(ax, -0.026, 0.026)

    ax = Axis(fig[2, 2]; xlabel, ylabel)
    mGM, MGM = plot_conductance_Phi(ax, "base_fs_szoom"*temp*"_Phis", 100; colorrange = (0, 1e-2    ))
    hideydecorations!(ax; ticks = false)

    ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"])
    ylims!(ax, -0.026, 0.026)

    Colorbar(fig[2, 3], colormap = :thermal, limits = (0, maximum([MGM, MGQ])), ticks = [0, 0.6], label = L"$G$ (e^2/h)", labelpadding = -30)


    colgap!(fig.layout, 1, 25)
    colgap!(fig.layout, 2, 5)
    return fig
end

fig = figure_conductance("_Zs")
save("figure_conductance_Zs.pdf", fig)
fig