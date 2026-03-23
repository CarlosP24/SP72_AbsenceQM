function build_barrier(h::Quantica.AbstractHamiltonian1D, p_wire::Union{Params, Params_Partial} , χ = "default"; pref = log(100)) 
    @unpack μ, a0 = p_wire

    if χ == "default"
        χ = 200
        if p_wire isa Params
            @unpack R = p_wire
            k0 = 2.4048  
            χ = R / k0                  # Default value for χ given by electrostatics
        end
    end

    L = pref * χ                    # Length of the wire so the potential decays to 1% )

    L = floor(L/a0)*a0

    U(z, μ, χ) = μ * exp(-z/χ)          # Axial potential variation given by electrostatics + depletion at border

    hf = h |> supercell(region = r -> 0 <= r[1] <= L)
    mod! = @onsite!((o, r; μ = μ, χ = χ) -> o + U(r[1], μ, χ) * σ0τz)

    return hf |> mod!, L
end