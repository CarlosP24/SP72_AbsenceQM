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
        Vmax = 50,
        μ = 14,
        preα = 70 * 40 / 50,
        ishollow = false,
        τΓ = 40,
        bandbottom = true,
    ),
    calc_params = Calc_Params()
)

full_shells = Dict(
    "base_fs" => base_fs,
)