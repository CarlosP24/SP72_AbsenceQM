function figure_wyS()
    fig = Figure(size = (600, 500), fontsize = 20)

    xlabel = L"$\chi$ (nm)"
    
    ylabel = L"$\omega / \Delta_0 \cdot 10^{1}$"

    ax = Axis(fig[1, 1]; xlabel, ylabel)
    plot_LDOS(ax, "base_partial_szoom", "Majo"; colorrange = (0, 1e-1), pref = 10 )
    hidexdecorations!(ax; ticks = false)
    ax.yticks = [-2, 0, 2]

    text!(ax, 200, 1; text = "MZM", color = :white, align = (:center, :center))
    text!(ax, 200, -1; text = L"V_\text{Z}=V_\text{Z}^{(1)}", color = :white, align = (:center, :center))

    text!(ax, 6, 1; text = "Partial-Shell", color = :white, align = (:center, :center))


    ax = Axis(fig[1, 2]; xlabel, ylabel)
    plot_LDOS(ax, "base_partial_szoom", "QMajo"; colorrange = (0, 1e-1), pref = 10 )
    hidexdecorations!(ax; ticks = false)
    hideydecorations!(ax; ticks = false)
    ax.yticks = [-2, 0, 2]

    text!(ax, 200, 1; text = "Q-MZM", color = :white, align = (:center, :center))
    text!(ax, 200, -1; text = L"V_\text{Z}=V_\text{Z}^{(2)}", color = :white, align = (:center, :center))

    ylabel = L"$\omega / \Delta_0 \cdot 10^{2}$"
    ax = Axis(fig[2, 1]; xlabel, ylabel)
    plot_LDOS(ax, "base_fs_szoom", "Majo"; colorrange = (0, 1e-2), pref = 100 )
    ax.yticks = [-3, 0, 3]

    text!(ax, 200, 3; text = "MZM", color = :white, align = (:center, :center))
    text!(ax, 200, -3; text = L"\Phi=\Phi^{(1)}", color = :white, align = (:center, :center))

    text!(ax, 5, 3; text = "Full-Shell", color = :white, align = (:center, :center))

    ax = Axis(fig[2, 2]; xlabel, ylabel)
    plot_LDOS(ax, "base_fs_szoom", "QMajo"; colorrange = (0, 5e-3), pref = 100 )
    hideydecorations!(ax; ticks = false)
    ax.yticks = [-3, 0, 3]

    text!(ax, 200, 3; text = "Q-MZM", color = :white, align = (:center, :center),)
    text!(ax, 200, -3; text = L"\Phi=\Phi^{(2)}", color = :white, align = (:center, :center))

    Colorbar(fig[1, 3], colormap = :thermal, limits = (0, 1), ticks = [0, 1], label = L"$$ LDOS (arb.  units)", labelpadding = -15)
    Colorbar(fig[2, 3], colormap = :thermal, limits = (0, 1), ticks = [0, 1], label = L"$$ LDOS (arb.  units)", labelpadding = -15)

    colgap!(fig.layout, 2, 5)

    style = (font = "CMU Serif Bold", fontsize   = 20)

    Label(fig[1, 1, TopLeft()], "a"; padding = (-20, 0, -40, 0), style...)
    Label(fig[1, 2, TopLeft()], "b"; padding = (-20, 0, -40, 0), style...)
    Label(fig[2, 1, TopLeft()], "c"; padding = (-20, 0, -40, 0), style...)
    Label(fig[2, 2, TopLeft()], "d"; padding = (-20, 0, -40, 0), style...)

    return fig
end

fig = figure_wyS()
save("plots/figures/fig_wyS.pdf", fig)
fig