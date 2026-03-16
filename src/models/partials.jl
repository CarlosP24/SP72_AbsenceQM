base_partial = Params_System(;
    params_wire = Params_Partial(;
        μ = 2,
        Δ = 0.23,
        α = 40,
        ),
    calc_params = Calc_Params(;
        ωrng = range(-0.26, 0, length = 301) .+ 5e-3im,)
    )

base_partial_szoom = Params_System(base_partial;
    calc_params = Calc_Params(base_partial.calc_params; 
        ωrng = range(-0.1, 0, length = 301) .+ 1e-3im,
    )
)

base_partial_szoom_weak = Params_System(base_partial_szoom ;
    calc_params = Calc_Params(base_partial_szoom.calc_params; 
        Vdis = 0.1 * 2
    )
)

base_partial_szoom_strong = Params_System(base_partial_szoom ;
    calc_params = Calc_Params(base_partial_szoom.calc_params; 
        Vdis = 2
    )
)

partials = Dict(
    "base_partial" => base_partial,
    "base_partial_szoom" => base_partial_szoom,
    "base_partial_szoom_weak" => base_partial_szoom_weak,
    "base_partial_szoom_strong" => base_partial_szoom_strong
)