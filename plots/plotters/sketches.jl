function lorentz_exp_profile(x; chi, gamma = 0.03, x0 = 0.125, x_join = 0.2, y_inf = 0.5, y_join = 0.7, ylimit = 1)
    d = 1 / ((x_join - x0)^2 + gamma^2) - 1 / (x0^2 + gamma^2)
    A = y_join / d

    lorentz(t) = A * (1 / ((t - x0)^2 + gamma^2) - 1 / (x0^2 + gamma^2))
    exp_tail(t) = y_inf + (y_join - y_inf) * exp(-chi * (t - x_join))
    y = x <= x_join ? lorentz(x) : exp_tail(x)
    return y < ylimit ? y : NaN
end

majorana(x, x0, freq, decay) = exp(-decay * (x-x0)) * sin(2π * freq * (x-x0))^2

function quasimajorana(x, x0, freq, decay, decay_majo; onset = decay / 4)
    gaussian = exp(-(x - x0)^2 / decay^2)

    if x <= x0
        return gaussian
    end

    right_branch = majorana(x, x0, freq, decay_majo)
    switch = 1 - exp(-((x - x0) / onset)^2)
    return (1 - switch) * gaussian + switch * right_branch
end

color_probe = colorant"#B4B4B4"
color_semi = colorant"#FBF6CB"
color_super = colorant"#B8C7F9"

color_majo = :darkred
color_quasi = :darkgreen

color_ins = (:gray, 0.2)
color_triv = :white
color_topo = (:red, 0.5)

## Sketch Partial 
function sketch_partial(pos; path = "plots/sketches/partial-shell.png")
    ax = Axis(pos; xlabel = L"z", alignmode = Mixed(left = -20, bottom = -30))


    xlims!(ax, 0, 1)
    ylims!(ax, 0, 1)
    hidexdecorations!(ax; label = false)
    hideydecorations!(ax) 

    band!(ax, [0, 0.05], 0.85, 0.95; color = color_probe)
    band!(ax, [0.05, 1.0], 0.85, 0.95; color = color_semi)
    band!(ax, [0.2, 1.0], 0.95, 1; color = color_super)

    arrows2d!(ax, [0.2], [0.8], [0.5], [0.8]; argmode = :endpoint, color = :red)
    text!(ax, 0.51, 0.8; text = L"B", color = :red, align = (:left, :center), fontsize = 16)

    imax = Axis(pos; 
        height = Relative(0.3),
        width = Relative(0.88),
        halign=2.8,
        valign=1.1,
        aspect = DataAspect())
    img = load(path)
    image!(imax, reverse(img, dims = 1)')
    hidespines!(imax)
    hidedecorations!(imax)

    hlines!(ax, 0.; color = (:black, 0.5), linewidth = 2)
    hlines!(ax, 0.4; color = (:black, 0.5), linewidth = 2)

    band!(ax, [0, 0.2], 0.6, 0.75; color = color_ins)
    band!(ax, [0.2, 1.0], 0.6, 0.75; color = color_topo)

    text!(ax, 0.25, 0.975; text = "SC", color = :white, align = (:left, :center), fontsize = 13)
    text!(ax, 0.25, 0.9; text = "SM", color = :black, align = (:left, :center), fontsize = 13)

    text!(ax, 0.12, 0.68; text = "Ins", color = :black, align = (:center, :center), rotation = π/2)
    text!(ax, 0.4, 0.68; text = "Topo", color = :white, align = (:center, :center),)
    text!(ax, 0.8, 0.68; text = L"V_\text{Z}^{(1)} > V_\text{Z}^\text{c}", color = :white, align = (:center, :center),)

    lines!(ax, [0.2, 0.2], [0.4, 0.58]; color = (:black, 0.5), linewidth = 2)
    text!(ax, 0.16, 0.49; text = L"\Psi", rotation = π/2, color = :black, align = (:center, :center), fontsize = 16)

    xrng = range(0, 1, length = 1000)
    yrng = lorentz_exp_profile.(xrng; gamma = 0.1, chi = 9, y_inf = 0.1, y_join = 0.2) .+ 0.4
    lines!(ax, xrng, yrng; color = :black, linewidth = 2)
    mbar!(ax, [0.19, 0.55], [0.5, 0.55]; color = :black, linewidth = 2)
    text!(ax, 0.51, 0.56; text = L"\chi", color = :black, align = (:left, :center), fontsize = 16)

    hlines!(ax, 0.6; color = :navyblue, linewidth = 2)
    text!(ax, 0.82, 0.52; text = L"\mu_\text{bulk}", color = :navyblue)
    text!(ax, 0.65, 0.43; text = "MZM", color = :black, fontsize = 16, )

    xrng = range(0.2, 1, length = 200)
    #lines!(ax, xrng, 0.22.*majorana.(xrng, 0.2,  12, 7) .+ 0.4; color = color_majo)
   ax_wf = Axis(pos;  
        width=Relative(0.88),
        height=Relative(0.18),
        halign=0.98,
        valign=0.47,)
    plot_wf(ax_wf, "base_partial";  key = "Majo", quasi = false, color_majo)
    hidespines!(ax_wf)
    hidedecorations!(ax_wf)
    xlims!(ax_wf, 0, 0.075)

    band!(ax, [0, 0.2], 0.2, 0.35; color = color_ins)
    band!(ax, [0.2, 0.5], 0.2, 0.35; color = color_topo)
    band!(ax, [0.5, 1], 0.2, 0.35; color = color_triv)

    text!(ax, 0.12, 0.28; text = "Ins", color = :black, align = (:center, :center), rotation = π/2)
    text!(ax, 0.35, 0.28; text = "Topo", color = :white, align = (:center, :center),)
    text!(ax, 0.57, 0.28; text = "Triv", color = :black, align = (:center, :center), rotation = π/2)
    text!(ax, 0.8, 0.28; text = L"V_\text{Z}^{(2)} < V_\text{Z}^\text{c}", color = :black, align = (:center, :center),)
    
    lines!(ax, [0.2, 0.2], [0, 0.18]; color = (:black, 0.5), linewidth = 2)
    text!(ax, 0.16, 0.09; text = L"\Psi", rotation = π/2, color = :black, align = (:center, :center), fontsize = 16)

    xrng = range(0, 1, length = 1000)
    yrng = lorentz_exp_profile.(xrng; gamma = 0.1, chi = 9, y_inf = 0.1, y_join = 0.2, ylimit = 0.35)

    lines!(ax, xrng, yrng; color = :black, linewidth = 2)
    hlines!(ax, 0.2; color = :navyblue, linewidth = 2)
    text!(ax, 0.82, 0.12; text = L"\mu_\text{bulk}", color = :navyblue)
    text!(ax, 0.75, 0.03; text = "Q-MZMs", color = :black, fontsize = 14, )

    xrng = range(0.2, 1, length = 200)

    ax_wf = Axis(pos;  
        width=Relative(0.88),
        height=Relative(0.18),
        halign=0.98,
        valign=-0.03,)
    plot_wf(ax_wf, "base_partial";  key = "QMajo", color_quasi, color_majo)
    hidespines!(ax_wf)
    hidedecorations!(ax_wf)
    xlims!(ax_wf, 0, 0.075)
    hidespines!(ax)

    text!(ax, 0.12, 0.92; text = L"U(z)", align = (:center, :center), fontsize = 16)

    return ax 
end

# fig = Figure(size = (0.5 * 600, 2/5 * 900), fontsize = 20)
# ax = Axis(fig[1:2, 1]; xlabel = L"z", )
# sketch_partial(ax)
# fig

## Sketch FS 
function sketch_FS(pos; path = "plots/sketches/full-shell.png")
    ax = Axis(pos; xlabel = L"z",  alignmode = Mixed(left = -20, bottom = -30))

    xlims!(ax, 0, 1)
    ylims!(ax, 0, 1)
    hidexdecorations!(ax; label = false)
    hideydecorations!(ax;) 

    band!(ax, [0, 0.05], 0.85, 0.95; color = color_probe)
    band!(ax, [0.05, 0.7], 0.85, 0.95; color = color_semi)
    band!(ax, [0.2, 0.7], 0.95, 1; color = color_super)
    band!(ax, [0.2, 0.7], 0.8, 0.85; color = color_super)


    hlines!(ax, 0.; color = (:black, 0.5), linewidth = 2)
    hlines!(ax, 0.4; color = (:black, 0.5), linewidth = 2)

    band!(ax, [0, 0.2], 0.6, 0.75; color = color_ins)
    band!(ax, [0.2, 0.3], 0.6, 0.75; color = color_triv)
    band!(ax, [0.3, 1.0], 0.6, 0.75; color = color_topo)

    arrows2d!(ax, [0.22], [0.9], [0.45], [0.9]; argmode = :endpoint, color = :red)
    text!(ax, 0.46, 0.9; text = L"B", color = :red, align = (:left, :center), fontsize = 16)

    imax = Axis(pos; 
        height = Relative(0.3),
        width = Relative(0.88),
        halign=2.8,
        valign=1.06,
        aspect = DataAspect())
    img = load(path)
    image!(imax, reverse(img, dims = 1)')
    hidespines!(imax)
    hidedecorations!(imax)


    text!(ax, 0.12, 0.68; text = "Ins", color = :black, align = (:center, :center), rotation = π/2)
    text!(ax, 0.25, 0.68; text = "Triv", color = :purple, align = (:center, :center), rotation = π/2)
    text!(ax, 0.5, 0.68; text = "Topo", color = :white, align = (:center, :center),)
    text!(ax, 0.8, 0.68; text = L"\Phi^{(1)} < \Phi^\text{c}", color = :white, align = (:center, :center),)

    lines!(ax, [0.2, 0.2], [0.4, 0.58]; color = (:black, 0.5), linewidth = 2)
    text!(ax, 0.16, 0.49; text = L"\Psi", rotation = π/2, color = :black, align = (:center, :center), fontsize = 16)

    xrng = range(0, 1, length = 1000)
    yrng = lorentz_exp_profile.(xrng; gamma = 0.1, chi = 9, y_inf = 0.1, y_join = 0.2) .+ 0.4
    lines!(ax, xrng, yrng; color = :black, linewidth = 2)


    hlines!(ax, 0.6; color = :navyblue, linewidth = 2)
    text!(ax, 0.82, 0.52; text = L"\mu_\text{bulk}", color = :navyblue)
    text!(ax, 0.35, 0.43; text = "MZM", color = :black, fontsize = 16, )

    xrng = range(0.3, 1, length = 200)
    ax_wf = Axis(pos;  
        width=Relative(0.88),
        height=Relative(0.18),
        halign=0.98,
        valign=0.47,)
    plot_wf(ax_wf, "base_fs";  key = "Majo", quasi = false, color_majo)
    hidespines!(ax_wf)
    hidedecorations!(ax_wf)
    xlims!(ax_wf, 0.022, 0.15)

    band!(ax, [0, 0.2], 0.2, 0.35; color = color_ins)
    band!(ax, [0.2, 3], 0.2, 0.35; color = color_triv)
    band!(ax, [0.3, 0.5], 0.2, 0.35; color = color_topo)
    band!(ax, [0.5, 1], 0.2, 0.35; color = color_triv)

    text!(ax, 0.12, 0.28; text = "Ins", color = :black, align = (:center, :center), rotation = π/2)
    text!(ax, 0.25, 0.28; text = "Triv", color = :purple, align = (:center, :center), rotation = π/2)
    text!(ax, 0.4, 0.28; text = "Topo", color = :white, align = (:center, :center),)
    text!(ax, 0.57, 0.28; text = "Triv", color = :black, align = (:center, :center), rotation = π/2)
    text!(ax, 0.8, 0.28; text = L"\Phi^{(2)} > \Phi^\text{c}", color = :black, align = (:center, :center),)

    lines!(ax, [0.2, 0.2], [0, 0.18]; color = (:black, 0.5), linewidth = 2)
    text!(ax, 0.16, 0.09; text = L"\Psi", rotation = π/2, color = :black, align = (:center, :center), fontsize = 16)

    xrng = range(0, 1, length = 1000)
    yrng = lorentz_exp_profile.(xrng; gamma = 0.1, chi = 9, y_inf = 0.1, y_join = 0.2, ylimit = 0.35)

    lines!(ax, xrng, yrng; color = :black, linewidth = 2)
    hlines!(ax, 0.2; color = :navyblue, linewidth = 2)
    text!(ax, 0.82, 0.12; text = L"\mu_\text{bulk}", color = :navyblue)
    text!(ax, 0.65, 0.03; text = "Q-MZMs", color = :black, fontsize = 16, )

    ax_wf = Axis(pos;  
        width=Relative(0.88),
        height=Relative(0.18),
        halign=0.98,
        valign=-0.03,)
    plot_wf(ax_wf, "base_fs";  key = "QMajo", color_quasi, color_majo)
    hidespines!(ax_wf)
    hidedecorations!(ax_wf)
    xlims!(ax_wf, 0.022, 0.15)

    hidespines!(ax)

    text!(ax, 0.12, 0.92; text = L"U(z)", align = (:center, :center), fontsize = 16)

    return ax 
end

# fig = Figure(size = (0.5 * 600, 2/5 * 900), fontsize = 20)
# ax = Axis(fig[1:2, 1]; xlabel = L"z", )
# sketch_FS(ax)
# fig