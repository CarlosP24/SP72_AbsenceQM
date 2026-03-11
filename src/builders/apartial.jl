@with_kw struct Params_Partial
    ħ2ome = 76.1996
    m0 = 0.023
    a0 = 5
    t = ħ2ome/(2m0*a0^2)
    μ = 0
    α = 0
    Δ = 0.23
    B = 0
    τΓ = 1
end

function build_partial(p::Params_Partial)
    @unpack a0, t, μ, α, Δ, B, τΓ = p

    lat = LP.square(; a0) |> supercell((1, 0))

    # Kinetic
    p2 = @onsite((r; μ = μ) ->
        σ0τz * (2*t - μ)
    ) + hopping((r, dr) ->
        -t * σ0τz, range = a0
    )

    # Rashba SOC
    rashba = @hopping((r, dr; α = α) ->
        α * im * dr[1] / (2 * a0^2) * σyτz, 
        range = a0
    )

    # Zeeman
    zeeman = @onsite((; B = B) ->
        σzτ0 *  B
    )

    # SM Hamiltonian
    hSM = lat |> hamiltonian(p2 + rashba + zeeman; orbitals = Val(4))

    # Superconductor
    Σ! = @onsite!((o, r; Δ = Δ, τΓ = τΓ) ->
        o + τΓ * Δ * σ0τx
    )

    hSC = hSM |> Σ!

    return hSM, hSC, p
end

