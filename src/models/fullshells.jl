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
        χ = 1000,
    )
)

base_fs_Zs = Params_System(base_fs;
    calc_params = Calc_Params(base_fs.calc_params; 
        Zs = -42:42
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
        ωrng = range(-0.2 * 0.23, 0, length = 301) .+ 1e-4im,
    )
)

base_fs_testing = Params_System(base_fs;
    calc_params = Calc_Params(base_fs.calc_params; 
        ωrng = range(-0.02 * 0.23, 0, length = 51) .+ 1e-8im,
        Φrng_DOS = range(0.501, 1.499, length = 51),
        χrng = 10 .^range(0, 3.5, length = 51)
    )
)

base_fs_sszoom = Params_System(base_fs;
    calc_params = Calc_Params(base_fs.calc_params; 
        ωrng = range(-0.2 * 0.23, 0, length = 301) .+ 1e-6im,
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
        χrng = 10 .^range(0, 3.5, length = 301),
        ωrng = range(-0.2 * 0.23, 0, length = 201) .+ 1e-6im,
        kBT = 0.08617 * 0.001,
        )
)

base_fs_szoom_Zs_Phis = Params_System(base_fs_szoom;
    calc_params = Calc_Params(base_fs_szoom.calc_params; 
        #Zs = -42:42
        Zs = -5:5,
        Φrng_PD = range(0, 2.499, length = 301),
        ωrng = range(-0.2 * 0.23, 0, length = 201) .+ 1e-6im,
        kBT = 0.08617 * 0.001,
    )
)

# 10mK
τs = range(0.1, 0.9, step = 0.05)

base_fs_szoom_zeroT = Params_System(base_fs_szoom;
    calc_params = Calc_Params(base_fs_szoom.calc_params; 
        kBT = 0,
        ωrng = range(-0.5 * 0.23, 0, step = 1e-5) .+ 2e-5im,
        Φrng_PD = range(0.501, 1.499, length = 101),
        χs = [5, 10]
    )
)

base_fs_szoom_lowT = Params_System(base_fs_szoom;
    calc_params = Calc_Params(base_fs_szoom.calc_params; 
        kBT = 0.08617 * 0.01,
        ωrng = range(-0.5 * 0.23, 0, step = 1e-5) .+ 2e-5im,
        Φrng_PD = range(0.501, 1.499, length = 101),
        χs = [5, 10]
    )
)

base_τs = Dict(
    "base_fs_tau=$(τ)" => Params_System(base_fs_szoom_lowT;
        calc_params = Calc_Params(base_fs_szoom_lowT.calc_params; 
            τ = τ,
            kBT = 0.08617 * 0.001,
        )
    ) for τ in τs
)

# 25mK
base_fs_szoom_midT = Params_System(base_fs_szoom;
    calc_params = Calc_Params(base_fs_szoom.calc_params; 
        kBT = 0.08617 * 0.04,
        ωrng = range(-0.5 * 0.23, 0, step = 1e-5) .+ 2e-5im,
        Φrng_PD = range(0.501, 1.499, length = 101),
        χs = [5, 10]
    )
)

# 100mK
base_fs_szoom_highT = Params_System(base_fs_szoom;
    calc_params = Calc_Params(base_fs_szoom.calc_params; 
        kBT = 0.08617 * 0.1,
        ωrng = range(-0.5 * 0.23, 0, step = 1e-5) .+ 2e-5im,
        Φrng_PD = range(0.501, 1.499, length = 101),
        χs = [5, 10]
    )
)

base_fs_fdos = Params_System(base_fs;
    calc_params = Calc_Params(base_fs.calc_params; 
        χ = 1000,
        ωrng = [0.0 + 1e-4im],
        Φrng_DOS = range(0.501, 1.499, length = 51),
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
    "base_fs_szoom_midT" => base_fs_szoom_midT,
    "base_fs_szoom_highT" => base_fs_szoom_highT,
    "base_fs_szoom_Zs_Phis" => base_fs_szoom_Zs_Phis,
    "base_fs_fdos" => base_fs_fdos,
    "base_fs_testing" => base_fs_testing,
    "base_fs_szoom_zeroT" => base_fs_szoom_zeroT,
) 

merge!(full_shells, base_τs)

# End LDOS vs (Φ, ω) on the grid of base_fs_zoom (paper Fig. 1h) for a progression of χ (talk)
base_fs_zoom_χs = Dict(
    "base_fs_zoom_chi=$(χ)" => Params_System(base_fs_zoom;
        calc_params = Calc_Params(base_fs_zoom.calc_params;
            χ = χ,
        )
    ) for χ in [5, 20, 200, 500, 1000]
)

merge!(full_shells, base_fs_zoom_χs)

# Hidden quasi-MZM pair vs χ (talk): m_J = 0 DOS at Φ^(2) on a log ω grid, from the gap edge
# (≈ 10⁻² Δ0) down to 10⁻⁶ Δ0, broadening 2 % of |ω|
base_fs_szoom_vchi = Params_System(base_fs_szoom;
    calc_params = Calc_Params(base_fs_szoom.calc_params;
        ωrng = [-w + 0.02im * w for w in 0.23 .* 10 .^ range(-6, log10(0.03), length = 450)],
    )
)

merge!(full_shells, Dict("base_fs_szoom_vchi" => base_fs_szoom_vchi))

# The same with the whole smooth profile (10χ before the bulk: the Φ^(2) topological segment
# ends at 7χ) and the grid down to 10⁻⁸ Δ0, 100 points per decade (key _dosvchiL). χ ≤ 1.5 µm:
# beyond, the pair is below 10⁻⁶ Δ0, and 12χ up to 3.16 µm (38 µm wires) ran out of memory
base_fs_szoom_vchiL = Params_System(base_fs_szoom;
    calc_params = Calc_Params(base_fs_szoom.calc_params;
        χrng = 10 .^ range(0, log10(1500), length = 300),
        ωrng = [-w + 0.02im * w for w in 0.23 .* 10 .^ range(-8, log10(0.03), length = 750)],
    )
)

merge!(full_shells, Dict("base_fs_szoom_vchiL" => base_fs_szoom_vchiL))

# Spin and momentum of the two halves of the hidden quasi-MZM pair at Φ^(2), both at smooth
# edges of the topological segment (talk check, key _pairspin)
base_fs_szoom_pair = Params_System(base_fs_szoom;
    calc_params = Calc_Params(base_fs_szoom.calc_params;
        χs = [100, 150, 200, 300, 500, 700, 1000],
    )
)

merge!(full_shells, Dict("base_fs_szoom_pair" => base_fs_szoom_pair))
