function figure_conductance(temp::String = "")
    fig = Figure(size = (600, 450), fontsize = 20)


    ax = Axis(fig[1, 1])
    plot_DOS(ax, "base_fs_Zs"; labels = false, colorrange = (0, 4))
    Φ = plot_TT(ax, "base_fs"; linewidth = 2, color = :white)

    ax.xlabel = L"$\Phi/\Phi_0$"
    ax.xticks = 0:0.5:2.5
    ax.yticks = ([-0.23, 0, 0.23], ["-1", "0", "1"]) 
    ylims!(ax, -0.026, 0.026)
    xlims!(ax, 0.501, 1.499)
    vlines!(ax, [0.65, 0.95]; color = :white)
    ax.xticks = ([0.501, Φ, 1, 1.499], ["0.5", L"\Phi^\text{c}", "1", "1.5"])
    ax.xlabel = L"$\Phi/\Phi_0$"
    ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"]) 
    ax.ylabel = L"$\omega$ ($\mu$eV)"
    ax.ylabelpadding = -15

    text!(ax, 1.34, 0; text = L"$\chi = 200$nm", color = :white, align = (:center, :center), fontsize = 14)


    ax = Axis(fig[1, 2])
    Φs = plot_DOS(ax, "base_fs_zoom"; colorrange = (5e-2, 5e-1))
    Φ = plot_TT(ax, "base_fs"; linewidth = 2, color = :white)
    ylims!(ax, -0.026, 0.026)
    xlims!(ax, 0.501, 1.499)
    hideydecorations!(ax; ticks = false)

    ax.xticks = ([0.501, Φ, 1, 1.499], ["0.5", L"\Phi^\text{c}", "1", "1.5"])
    ax.xlabel = L"$\Phi/\Phi_0$"
    ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"]) 
    ax.ylabelpadding = -15

    text!(ax, 1.34, 0; text = L"$\chi = 200$nm", color = :white, align = (:center, :center), fontsize = 14)

    vlines!(ax, [0.65, 0.95]; color = :white)


    xlabel = L"$\chi$ (nm)"
    ylabel = L"$V$ ($\mu$V)"

    ax = Axis(fig[2, 1]; xlabel, ylabel)
    mGM, MGM = plot_conductance(ax, "base_fs_szoom"*temp, "Majo";)

    ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"])
    ylims!(ax, -0.026, 0.026)

    text!(ax, 200, 0.015; text = "MZM", color = :white, align = (:center, :center))
    text!(ax, 200, -0.015; text = L"\Phi=\Phi^{(1)}", color = :white, align = (:center, :center))
    
    ax = Axis(fig[2, 2]; xlabel, ylabel)
    mGQ, MGQ = plot_conductance(ax, "base_fs_szoom"*temp, "QMajo";  )
    hideydecorations!(ax; ticks = false)

    ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"])
    ylims!(ax, -0.026, 0.026)

    text!(ax, 200, 0.015; text = "Q-MZM", color = :white, align = (:center, :center))
    text!(ax, 200, -0.015; text = L"\Phi=\Phi^{(2)}", color = :white, align = (:center, :center))
    
    Colorbar(fig[1, 3], colormap = :thermal, limits = (0, 1), ticks = [0,  1], label = L"$$ DOS (arb.  units)", labelpadding = -15, labelsize = 16)
    Colorbar(fig[2, 3], colormap = :thermal, limits = (0, maximum([MGM, MGQ])), ticks = [0, 2], label = L"$G$ (e^2/h)", labelpadding = -15, labelsize = 16)

    colgap!(fig.layout, 1, 25)
    colgap!(fig.layout, 2, 5)
    return fig
end

fig = figure_conductance("_Zs")
save("figure_conductance_Zs.pdf", fig)
fig