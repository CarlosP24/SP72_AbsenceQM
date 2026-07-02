base_partial = Params_System(;
    params_wire = Params_Partial(;
        μ = 2,
        Δ0 = 0.23,
        α = 40,
        Bc = 2 * sqrt(2^2 + 0.23^2),
        τΓ = 3,
        ),
    calc_params = Calc_Params(;
        ωrng = range(-0.26, 0, length = 301) .+ 5e-3im,)
    )

base_partial_szoom = Params_System(base_partial;
    calc_params = Calc_Params(base_partial.calc_params; 
        ωrng = range(-0.2 * 0.23, 0, length = 301) .+ 1e-4im,
    )
)

base_partial_szoom_weak = Params_System(base_partial_szoom ;
    calc_params = Calc_Params(base_partial_szoom.calc_params; 
        Vdis = 0.4 * 0.8 * 0.23 * sqrt(10^2.9 / 5)
    )
)

base_partial_szoom_strong = Params_System(base_partial_szoom ;
    calc_params = Calc_Params(base_partial_szoom.calc_params; 
        Vdis = 5 * 0.8 * 0.23 * sqrt(10^2.9 / 5)
    )
)

base_partial_szoom_lowT = Params_System(base_partial_szoom;
    calc_params = Calc_Params(base_partial_szoom.calc_params; 
        kBT = 0.08617 * 0.001,
        ωrng = range(-0.2 * 0.23, 0, length = 51) .+ 1e-6im,
        χrng = 10 .^range(0, 1.1, length = 51),
    )
)

partials = Dict(
    "base_partial" => base_partial,
    "base_partial_szoom" => base_partial_szoom,
    "base_partial_szoom_weak" => base_partial_szoom_weak,
    "base_partial_szoom_strong" => base_partial_szoom_strong,
    "base_partial_szoom_lowT" => base_partial_szoom_lowT
)