fig = Figure()
ax = Axis(fig[1, 1])

plot_wf(ax, "base_fs_fdos";  key = "Majo", quasi = true,)
fig
