function Vdis(Nn, L, χ, Vs)
    V(x) = sum([Vs[m] * sin(2π * (x/χ) * Nn/m) for m in 1:Nn]) * sin(π * x/L) / sqrt(Nn)
    return V
end

function build_disorder(h::Quantica.AbstractHamiltonian1D, p_wire::Union{Params, Params_Partial}, uni = true,  Nn = 10, χ = "default")
    @unpack µ, a0 = p_wire

    if χ == "default"
        χ = 200
        if p_wire isa Params
            @unpack R = p_wire
            k0 = 2.4048  
            χ = R / k0                  # Default value for χ given by electrostatics
        end
    end

    L = log(100) * χ                    # Length of the wire so the potential decays to 1% of its maximum value (allows for χ to go up to 5χ_electrostatic)

    L = floor(L/a0)*a0
    
    Vs = randn(Nn) .* µ
    Vn(χ) = randn(Nn) .* µ

    hf = h |> supercell(region = r -> 0 <= r[1] <= L)
    mod! = @onsite!((o, r; χ = χ) -> o + uni * Vdis(Nn, L,χ, Vs)(r[1]) * σ0τz + !uni * Vdis(Nn, L, χ, Vn(χ))(r[1]) * σ0τz)

    return hf |> mod!, L
end