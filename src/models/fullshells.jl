base_fs = Params_System(;
    params_wire = Params(;
        R = 70,
        w = 70,
        d = 10,
        a0 = 5,
        Δ0 = 0.23,
        ξd = 70,
        g = 10,
        α = 0,
        Vmin = 0,
        Vmax = 60,
        μ = 22.8,
        preα = 70 * 7 / 60,
        ishollow = false,
        τΓ = 40,
        bandbottom = true,
    ),
    calc_params = Calc_Params(;
        χ = 500
    )
)

base_fs_zoom = Params_System(base_fs;
    calc_params = Calc_Params(base_fs.calc_params; 
        ωrng = range(-0.026, 0, length = 301) .+ 1e-4im,
        Φrng_DOS = range(0.501, 1.499, length = 301),
        μrng = range(21, 24, length = 500)
    )
)

base_fs_szoom = Params_System(base_fs;
    calc_params = Calc_Params(base_fs.calc_params; 
        ωrng = range(-0.01, 0, length = 301) .+ 1e-3im,
    )
)

full_shells = Dict(
    "base_fs" => base_fs,
    "base_fs_zoom" => base_fs_zoom,
    "base_fs_szoom" => base_fs_szoom,
)