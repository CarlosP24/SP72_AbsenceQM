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
        χ = 500,
    )
)

base_fs_Zs = Params_System(base_fs;
    calc_params = Calc_Params(base_fs.calc_params; 
        Zs = -42:42
    )
)

base_fs_zoom = Params_System(base_fs;
    calc_params = Calc_Params(base_fs.calc_params; 
        ωrng = range(-0.026, 0, length = 101) .+ 1e-4im,
        Φrng_DOS = range(0.501, 1.499, length = 101),
        μrng = range(21, 24, length = 500)
    )
)

base_fs_szoom = Params_System(base_fs;
    calc_params = Calc_Params(base_fs.calc_params; 
        ωrng = range(-0.2 * 0.23, 0, length = 301) .+ 1e-4im,
    )
)

base_fs_sszoom = Params_System(base_fs;
    calc_params = Calc_Params(base_fs.calc_params; 
        ωrng = range(-0.2 * 0.23, 0, length = 301) .+ 1e-4im,
    )
)

base_fs_alphazoom = Params_System(base_fs;
    calc_params = Calc_Params(base_fs.calc_params; 
        αrng = range(0, 100, length = 500),
        μrng = range(0, 35, length = 500)
    )
)

base_fs_hex = Params_System(base_fs;
    calc_params = Calc_Params(base_fs.calc_params;
        Zs = 0:6:42
    )
)

base_fs_szoom_weak = Params_System(base_fs_szoom;
    calc_params = Calc_Params(base_fs_szoom.calc_params; 
        Vdis = 0.5 * 0.08 * 0.23 * sqrt(10^2.9 / 5)
    )
)

base_fs_szoom_strong = Params_System(base_fs_szoom;
    calc_params = Calc_Params(base_fs_szoom.calc_params; 
        Vdis = 5 * 0.8 * 0.23 * sqrt(10^2.9 / 5)
    )
)

base_fs_szoom_Zs = Params_System(base_fs_szoom;
    calc_params = Calc_Params(base_fs_szoom.calc_params; 
        #Zs = -42:42
        Zs = -5:5,
        χrng = 10 .^range(0, 2.9, length = 100),
        ωrng = range(-0.2 * 0.23, 0, length = 401) .+ 1e-6im,
        τ = 1e-1
    )
)

base_fs_szoom_Zs_Phis = Params_System(base_fs_szoom;
    calc_params = Calc_Params(base_fs_szoom.calc_params; 
        #Zs = -42:42
        Zs = -5:5,
        Φrng_PD = range(0.501, 1.499, length = 101),
        ωrng = range(-0.2 * 0.23, 0, length = 101) .+ 1e-5im,
        τ = 1e-1
    )
)

# 10mK
base_fs_szoom_lowT = Params_System(base_fs_szoom;
    calc_params = Calc_Params(base_fs_szoom.calc_params; 
        kBT = 0.08617 * 0.01,
        ωrng = range(-0.2 * 0.23, 0, length = 101) .+ 1e-6im,
        τ = 1e-1
    )
)

# 100mK
base_fs_szoom_highT = Params_System(base_fs_szoom;
    calc_params = Calc_Params(base_fs_szoom.calc_params; 
        kBT = 0.08617 * 0.1,
        ωrng = range(-0.2 * 0.23, 0, length = 101) .+ 1e-6im,
        τ = 1e-1
    )
)

full_shells = Dict(
    "base_fs" => base_fs,
    "base_fs_alphazoom" => base_fs_alphazoom,
    "base_fs_Zs" => base_fs_Zs,
    "base_fs_zoom" => base_fs_zoom,
    "base_fs_szoom" => base_fs_szoom,
    "base_fs_hex" => base_fs_hex,
    "base_fs_szoom_weak" => base_fs_szoom_weak,
    "base_fs_szoom_strong" => base_fs_szoom_strong,
    "base_fs_sszoom" => base_fs_sszoom,
    "base_fs_szoom_Zs" => base_fs_szoom_Zs,
    "base_fs_szoom_lowT" => base_fs_szoom_lowT,
    "base_fs_szoom_highT" => base_fs_szoom_highT,
    "base_fs_szoom_Zs_Phis" => base_fs_szoom_Zs_Phis,
) 