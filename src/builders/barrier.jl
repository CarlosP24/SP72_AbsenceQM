k1 = besselj_zero(0, 1) 
function bessel_barrier_kernel(R, N)
    ks = [besselj_zero(0, ν) for ν in 1:N]
    ws = [1.0 / (ks[ν] * besselj(1, ks[ν])) for ν in 1:N]

    function U(z, r, μ, χ)
        s = 0.0
        rR = r / R
        @inbounds for ν in 1:N
            s += ws[ν] * besselj(0, ks[ν] * rR) * exp(-ks[ν] * z / (k1 *  χ))
        end
        return 2μ * s
    end
    return U
end

function build_barrier(h::Quantica.AbstractHamiltonian1D, p_wire::Params, χ = "default"; pref = log(100), N = 100) 
    @unpack μ, a0, R = p_wire

    if χ == "default"
        χ = R / k1                  # Default value for χ given by electrostatics
    end

    L = pref * χ                    # Length of the wire so the potential decays to 1% )

    L = floor(L/a0)*a0

    #U(z, μ, χ) = μ * exp(-z/χ)          # Axial potential variation given by electrostatics + depletion at border

    #U(z, μ, χ) = (2 * μ / π) * atan(1 / sinh(π * z / χ))  # Axial potential variation given by electrostatics + depletion at border

    U = bessel_barrier_kernel(R, N)

    hf = h |> supercell(region = r -> 0 <= r[1] <= L)
    mod! = @onsite!((o, r; μ = μ, χ = χ) -> o + U(r[1], r[2], μ, χ) * σ0τz)

    return hf |> mod!, L
end

function build_barrier(h::Quantica.AbstractHamiltonian1D, p_wire::Params_Partial , χ = "default"; pref = log(100), N = 20) 
    @unpack μ, a0 = p_wire

    if χ == "default"
        χ = 200
    end

    L = pref * χ                    # Length of the wire so the potential decays to 1% )

    L = floor(L/a0)*a0

    U(z, μ, χ) = μ * exp(-z/χ)          # Axial potential variation given by electrostatics + depletion at border

    #U(z, μ, χ) = (2 * μ / π) * atan(1 / sinh(π * z / χ))  # Axial potential variation given by electrostatics + depletion at border

    #U = bessel_barrier_kernel(R, N)

    hf = h |> supercell(region = r -> 0 <= r[1] <= L)
    mod! = @onsite!((o, r; μ = μ, χ = χ) -> o + U(r[1], μ, χ) * σ0τz)

    return hf |> mod!, L
end