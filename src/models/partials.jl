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
        ωrng = range(-0.05, 0, length = 301) .+ 1e-3im,
    )
)

partials = Dict(
    "base_partial" => base_partial,
    "base_partial_szoom" => base_partial_szoom,
)