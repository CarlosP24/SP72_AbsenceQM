base_partial = Params_System(;
    params_wire = Params_Partial(;
        μ = 2,
        Δ = 0.23,
        α = 40,
        )
    )

partials = Dict(
    "base_partial" => base_partial,
)