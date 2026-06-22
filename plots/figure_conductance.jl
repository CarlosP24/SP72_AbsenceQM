function figure_conductance(temp::String = ""; Φs = [0.65, 0.88], color_loop1 = [:lightgreen, :lightblue], color_loop2 = [:yellow, :pink], χs = [5, 1000])
    fig = Figure(size = (600, 450), fontsize = 20)


    xlabel = L"$\chi$ (nm)"
    ylabel = L"$V$ ($\mu$V)"

    xticks = ([1, 10^1, 10^2, 10^3], [L"1", L"10", L"100", L"1000"])


    ax = Axis(fig[1, 1]; xlabel, ylabel, xticks)
    mGM, MGM = plot_conductance(ax, "base_fs_szoom"*temp, "Majo"; colorrange = (0, 0.5))
    ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"])
    ylims!(ax, -0.026, 0.026)

    text!(ax, 800, 0.015; text = "MZM", color = :white, align = (:center, :center))
    text!(ax, 800, -0.015; text = L"\Phi=\Phi^{(1)}", color = :white, align = (:center, :center))
    scatter!(ax, 180, -0.015; color = color_loop1[1], marker = :circle, markersize = 10)

    vlines!(ax, χs, ymax = 0.1, color = color_loop2, linewidth = 4 )

    ax = Axis(fig[1, 2]; xlabel, ylabel, xticks)
    mGQ, MGQ = plot_conductance(ax, "base_fs_szoom"*temp, "QMajo"; colorrange = (0, 0.5) )
    hideydecorations!(ax; ticks = false)

    ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"])
    ylims!(ax, -0.026, 0.026)

    text!(ax, 800, 0.015; text = "Q-MZM", color = :white, align = (:center, :center))
    text!(ax, 800, -0.015; text = L"\Phi=\Phi^{(2)}", color = :white, align = (:center, :center))
    scatter!(ax, 180, -0.015; color = color_loop1[2], marker = :circle, markersize = 10)

    vlines!(ax, χs, ymax = 0.1, color = color_loop2, linewidth = 4 )

    Colorbar(fig[1, 3], colormap = :thermal, limits = (0, 0.5), ticks = [0, 0.5], label = L"$G$ (e^2/h)", labelpadding = -32, highclip = to_colormap(:thermal) |> last)


    xlabel = L"$\Phi / \Phi_0$"
    ax = Axis(fig[2, 1]; xlabel, ylabel)
    mGM, MGM = plot_conductance_Phi(ax, "base_fs_szoom"*temp*"_Phis", χs[1]; colorrange = (0, 2))
    Φ = plot_TT(ax, "base_fs"; linewidth = 2, color = :white)
    text!(ax, 1, -0.022; text = L"\Phi^\text{c}", color = :white, align = (:center, :center))
    
    ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"])
    ylims!(ax, -0.026, 0.026)

    vlines!(ax, [0.5, 1.5]; color = :gray, linestyle = :dot)
    vlines!(ax, Φs, ymin = 0.9, color = color_loop1, linewidth = 4 )

    text!(ax, 2, 0.015; text = L"$\chi = %$(χs[1])$nm", color = :white, align = (:center, :center))
    scatter!(ax, 1.5, 0.015; color = color_loop2[1], marker = :circle, markersize = 10)

    ax = Axis(fig[2, 2]; xlabel, ylabel)
    mGQ, MGQ = plot_conductance_Phi(ax, "base_fs_szoom"*temp*"_Phis", χs[2]; colorrange = (0, 2))
    Φ = plot_TT(ax, "base_fs"; linewidth = 2, color = :white)
    text!(ax, 1, -0.022; text = L"\Phi^\text{c}", color = :white, align = (:center, :center))

    hideydecorations!(ax; ticks = false)


    ax.yticks = ([-0.02, 0, 0.02], ["-20", "0", "20"])
    ylims!(ax, -0.026, 0.026)

    vlines!(ax, [0.5, 1.5]; color = :gray, linestyle = :dot)
    vlines!(ax, Φs, ymin = 0.9, color = color_loop1, linewidth = 4 )

    text!(ax, 1.9, 0.015; text = L"$\chi = %$(χs[2])$nm", color = :white, align = (:center, :center))
    scatter!(ax, 1.2, 0.015; color = color_loop2[2], marker = :circle, markersize = 10)

    Colorbar(fig[2, 3], colormap = :thermal , limits = (0, 2), ticks = [0, 2], label = L"$G (e^2/h)$", labelpadding = -15)

    style = (font = "CMU Serif Bold", fontsize   = 20)
    Label(fig[1, 1, TopLeft()], "a"; padding = (-40, 0, -20, 0), style...)
    Label(fig[1, 2, TopLeft()], "b"; padding = (-20, 0, -20, 0), style...)
    Label(fig[2, 1, TopLeft()], "c"; padding = (-40, 0, -20, 0), style...)
    Label(fig[2, 2, TopLeft()], "d"; padding = (-20, 0, -20, 0), style...)

    colgap!(fig.layout, 2, 5)

    rowgap!(fig.layout, 1, 5)
    return fig
end

fig = figure_conductance("_Zs")
save("plots/figures/SFig_Conductance.pdf", fig)
fig