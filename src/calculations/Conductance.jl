fermi_kernel(δω, kBT) = inv(4 * kBT) * sech(δω / (2 * kBT))^2

#tau(χ) = 10^(-0.3 * log10(χ)^2 + 0.22 * log10(χ) - 1)
#tau(χ) = 1e-1

function thermal_broadening_plan(ωvals::AbstractVector, kBT::Real)
    kBT > 0 || throw(ArgumentError("kBT must be positive to build a thermal broadening plan."))

    nω = length(ωvals)
    nω >= 2 || throw(ArgumentError("At least two energies are required for thermal broadening."))

    dω = ωvals[2] - ωvals[1]
    lags = collect(-(nω - 1):(nω - 1))
    kfull = fermi_kernel.(lags .* dω, kBT) .* dω
    kfull ./= sum(kfull)    # normalize: discrete sum may exceed 1 when kBT << dω

    nk = length(kfull)
    nconv = nω + nk - 1
    nfft = nextpow(2, nconv)
    kpad = vcat(kfull, zeros(eltype(kfull), nfft - nk))

    return (; nω, nfft, nconv, kfft = fft(kpad))
end

function thermal_broaden_conductance(Gω::AbstractVector, plan)
    nω = plan.nω
    nω == length(Gω) || throw(ArgumentError("Gω and ωvals must have the same length."))

    g = real.(float.(Gω))
    nfft = plan.nfft
    nconv = plan.nconv

    gpad = vcat(g, zeros(eltype(g), nfft - nω))
    c = real.(ifft(fft(gpad) .* plan.kfft))[1:nconv]

    # Extract linear-convolution segment corresponding to GT[j] = Σᵢ G[i] K(ωᵢ-ωⱼ) dω
    return c[nω:(2nω - 1)]
end

function apply_thermal_broadening!(Cond::Dict, ωrng, kBT)
    kBT > 0 || return Cond
    ωvals = real.(ωrng)
    one_sided = maximum(ωvals) <= 0 && minimum(ωvals) < 0

    if one_sided
        ωvals_sym = vcat(ωvals, -reverse(ωvals)[2:end])
        planT = thermal_broadening_plan(ωvals_sym, kBT)
        for (key, CZ) in pairs(Cond)
            CT = Matrix{Float64}(undef, size(CZ))
            for i in axes(CZ, 1)
                row = @view CZ[i, :]
                row_sym = vcat(row, reverse(row)[2:end])
                rowT_sym = thermal_broaden_conductance(row_sym, planT)
                @views CT[i, :] .= rowT_sym[1:length(ωvals)]
            end
            Cond[key] = CT
        end
    else
        planT = thermal_broadening_plan(ωvals, kBT)
        for (key, CZ) in pairs(Cond)
            CT = Matrix{Float64}(undef, size(CZ))
            for i in axes(CZ, 1)
                @views CT[i, :] .= thermal_broaden_conductance(CZ[i, :], planT)
            end
            Cond[key] = CT
        end
    end
    return Cond
end

# function convolve(f, g, t; lo=-Inf, hi=Inf; kwargs...)
#     integrand(τ) = f(τ) * g(t - τ)
#     val, err = quadgk(integrand, lo, hi; kwargs...)
#     return val
# end

function build_NS(params_wire::Union{Params, Params_Partial}, χ)
    hSM, hSC, params_wire = build(params_wire)
    hSstep, L = build_barrier(hSC, params_wire, χ)


    atolx = params_wire.a0 / 10
    left_face = r -> abs(r[1]) <= atolx
    right_face = r -> abs(r[1] - L) <= atolx

    gN_inf = hSM |> greenfunction(GS.Schur(boundary = 0))

    gS_inf = hSC |> greenfunction(GS.Schur(boundary = 0))
    coupling = build_coupling(params_wire)
    g = hSstep |>
        attach(gS_inf; region = right_face) |>
        attach(gN_inf, coupling; region = left_face) |>
        greenfunction()

    return g
end

function convolve(f, g, t; lo=-Inf, hi=Inf, kwargs...)
    integrand(τ) = f(τ) * g(t - τ)
    val, err = quadgk(integrand, lo, hi; kwargs...)
    return val
end

function fermi_dirac_deriv(V, kBT)
    kBT == 0 && error("T=0: use a delta function / don't broaden")
    x = V / (2*kBT)
    # sech(x)^2 = 1/cosh(x)^2 ; guard against overflow for large |x|
    return abs(x) > 40 ? 0.0 : (1/(4*kBT)) * sech(x)^2
end

function calc_conductance(name::String)
    system = systems[name]

    @unpack χrng, ωrng, Zs, Φs, kBT, τ, outdir = system.calc_params

    path = "$(outdir)/Conductance/$(name).jld2"
    mkpath(dirname(path))

    #g = build_NS(system.params_wire, maximum(χrng))

    #G = conductance(g[2, 2]; nambu = true)

    width = 40 * kBT

    Cond = pfunction(
        (χ, V, Z, Φ) -> 
        try
            Vr = real(V)
            Vi = imag(V)
            g = build_NS(system.params_wire, χ)
            G = conductance(g[2, 2]; nambu = true)
            G0(ω) = G(ω + Vi*1im; ω = ω + Vi*1im, Φ, Z, χ, τ)
            if kBT == 0
                return G0(V)
            end
            integrand(ω) = G0(ω) * fermi_dirac_deriv(real(V) - ω, kBT)
            val, err = quadgk(integrand, Vr - width, Vr + width )
            return val
        catch e
            @warn "Error calculating conductance at (Φ=$Φ, V=$V, Z=$Z): $e"
            NaN
        end,
        [χrng, ωrng, Zs, Φs];
    )

    Cond = sum(Cond; dims = 3)
    
    Cond = dropdims(Cond, dims = 3) 

    Cond = Dict(
        name => Cond[:, :, i] for (i, name) in enumerate(["Majo", "QMajo"])
    )

    #apply_thermal_broadening!(Cond, ωrng, kBT)

    return Results(
        system = system,
        G = Cond,
        path = path,
    )

end

function calc_conductance_Φ(name::String)
    system = systems[name]

    @unpack Φrng_PD, ωrng, Zs, χs, kBT, τ, outdir = system.calc_params

    path = "$(outdir)/Conductance_Phi/$(name).jld2"
    mkpath(dirname(path))

    width = 40 * kBT

    Cond = pfunction(
        (Φ, V, Z, χ) -> try
            g = build_NS(system.params_wire, χ)
            G = conductance(g[2, 2]; nambu = true)
            Vr = real(V)
            Vi = imag(V)
            g = build_NS(system.params_wire, χ)
            G = conductance(g[2, 2]; nambu = true)
            G0(ω) = G(ω + Vi*1im; ω = ω + Vi*1im, Φ, Z, χ, τ)
            if kBT == 0
                return G0(V)
            end
            integrand(ω) = G0(ω) * fermi_dirac_deriv(real(V) - ω, kBT)
            val, err = quadgk(integrand, Vr - width, Vr + width )
            return val
        catch e
            @warn "Error calculating conductance at (Φ=$Φ, ω=$ω, Z=$Z): $e"
            NaN
        end,
        [Φrng_PD, ωrng, Zs, χs];
    )

    Cond = sum(Cond; dims = 3)
    
    Cond = dropdims(Cond, dims = 3) 

    Cond = Dict(
        χ => Cond[:, :, i] for (i, χ) in enumerate(χs)
    )

    #apply_thermal_broadening!(Cond, ωrng, kBT)

    return Results(
        system = system,
        G = Cond,
        path = path,
    )

end

function calc_conductance_τ(name::String)
    system = systems[name]

    if system.params_wire isa Params_Partial
        res = calc_conductance_Pτ(name)
        return res
    end

    @unpack τrng, ωrng, Zs, Φs, χs, kBT, τ, outdir = system.calc_params

    path = "$(outdir)/Conductance_Tau/$(name).jld2"
    mkpath(dirname(path))

    g = build_NS(system.params_wire, χs[1])
    G = conductance(g[2, 2]; nambu = true)

    width = 40 * kBT


    Cond = pfunction(
        (τ, V, Z, Φ) -> try
            Vr = real(V)
            Vi = imag(V)
            G0(ω) = G(ω + Vi*1im; ω = ω + Vi*1im, Φ, Z, τ)
            if kBT == 0
                return G0(V)
            end
            integrand(ω) = G0(ω) * fermi_dirac_deriv(real(V) - ω, kBT)
            val, err = quadgk(integrand, Vr - width, Vr + width )
            return val
        catch e
            @warn "Error calculating conductance at (Φ=$Φ, ω=$ω, Z=$Z): $e"
            NaN
        end,
        [τrng, ωrng, Zs, Φs];
    )

    Cond = sum(Cond; dims = 3)
    
    Cond = dropdims(Cond, dims = 3) 

    Cond = Dict(
        name => Cond[:, :, i] for (i, name) in enumerate(["Majo", "QMajo"])
    )

    #apply_thermal_broadening!(Cond, ωrng, kBT)

    return Results(
        system = system,
        G = Cond,
        path = path,
    )

end

function calc_conductance_Pτ(name::String)
    system = systems[name]

    @unpack τrng, ωrng, Bs, χs, kBT, τ, outdir = system.calc_params

    path = "$(outdir)/Conductance_Tau/$(name).jld2"
    mkpath(dirname(path))

    g = build_NS(system.params_wire, χs[1])
    G = conductance(g[2, 2]; nambu = true)

    width = 40 * kBT

    Cond = pfunction(
        (τ, V, B) -> try
            Vr = real(V)
            Vi = imag(V)
            G0(ω) = G(ω + Vi*1im; ω = ω + Vi*1im, B, τ)
            if kBT == 0
                return G0(V)
            end
            integrand(ω) = G0(ω) * fermi_dirac_deriv(real(V) - ω, kBT)
            val, err = quadgk(integrand, Vr - width, Vr + width )
            return val
        catch e
            @warn "Error calculating conductance at (B=$B, V=$V, τ=$τ): $e"
            NaN
        end,
        [τrng, ωrng, Bs];
    )

    
    Cond = Dict(
        name => Cond[:, :, i] for (i, name) in enumerate(["Majo", "QMajo"])
    )

    #apply_thermal_broadening!(Cond, ωrng, kBT)

    return Results(
        system = system,
        G = Cond,
        path = path,
    )

end