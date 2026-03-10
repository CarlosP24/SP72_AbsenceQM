function build_barrier(h::Quantica.AbstractHamiltonian1D, p_wire::Params)
    @unpack μ, R, a0 = p_wire
    k0 = 2.4048 / R                         # First zero of J0
    χ = R/k0                                # Upper bound for χ given by electrostatics

    L = log(100) * χ                    # Length of the wire so the potential decays to 1% of its maximum value (allows for χ to go up to 5χ_electrostatic)

    L = floor(L/a0)*a0

    U(z, μ, χ) = μ * exp(-z/χ)              # Axial potential variation given by electrostatics + depletion at border

    hf = h |> supercell(region = r -> 0 <= r[1] <= L)
    mod! = @onsite!((o, r; μ = μ, χ = χ) -> o + U(r[1], μ, χ) * σ0τz)

    return hf |> mod!, L
end