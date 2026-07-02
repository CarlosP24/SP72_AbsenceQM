fermi_kernel(δω, kBT) = inv(4 * kBT) * sech(δω / (2 * kBT))^2

#tau(χ) = 10^(-0.3 * log10(χ)^2 + 0.22 * log10(χ) - 1)
tau(χ) = 1e-1

function thermal_broadening_plan(ωvals::AbstractVector, kBT::Real)
    kBT > 0 || throw(ArgumentError("kBT must be positive to build a thermal broadening plan."))

    nω = length(ωvals)
    nω >= 2 || throw(ArgumentError("At least two energies are required for thermal broadening."))

    dω = ωvals[2] - ωvals[1]
    lags = collect(-(nω - 1):(nω - 1))
    kfull = fermi_kernel.(lags .* dω, kBT) .* dω

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

function build_NS(params_wire::Params, χ)
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

function calc_conductance(name::String)
    system = systems[name]

    @unpack χrng, ωrng, Zs, Φs, kBT, outdir = system.calc_params

    path = "$(outdir)/Conductance/$(name).jld2"
    mkpath(dirname(path))

    #g = build_NS(system.params_wire, maximum(χrng))

    #G = conductance(g[2, 2]; nambu = true)

    Cond = pfunction(
        (χ, ω, Z, Φ) -> try
            g = build_NS(system.params_wire, χ)
            G = conductance(g[2, 2]; nambu = true)
            G(ω; ω, Φ, Z, χ, τ = tau(χ))
        catch e
            @warn "Error calculating conductance at (Φ=$Φ, ω=$ω, Z=$Z): $e"
            NaN
        end,
        [χrng, ωrng, Zs, Φs];
    )

    Cond = sum(Cond; dims = 3)
    
    Cond = dropdims(Cond, dims = 3) 

    Cond = Dict(
        name => Cond[:, :, i] for (i, name) in enumerate(["Majo", "QMajo"])
    )

    if kBT > 0
        ωvals = real.(ωrng)

        one_sided = maximum(ωvals) <= 0 && minimum(ωvals) < 0

        if one_sided
            ωvals_sym = vcat(ωvals, -reverse(ωvals)[2:end])
            planT = thermal_broadening_plan(ωvals_sym, kBT)

            for (Z, CZ) in pairs(Cond)
                CT = Matrix{Float64}(undef, size(CZ))
                for iΦ in axes(CZ, 1)
                    row = @view CZ[iΦ, :]
                    row_sym = vcat(row, reverse(row)[2:end])
                    rowT_sym = thermal_broaden_conductance(row_sym, planT)
                    @views CT[iΦ, :] .= rowT_sym[1:length(ωvals)]
                end
                Cond[Z] = CT
            end
        else
            planT = thermal_broadening_plan(ωvals, kBT)
            for (Z, CZ) in pairs(Cond)
                CT = Matrix{Float64}(undef, size(CZ))
                for iΦ in axes(CZ, 1)
                    @views CT[iΦ, :] .= thermal_broaden_conductance(CZ[iΦ, :], planT)
                end
                Cond[Z] = CT
            end
        end
    end

    return Results(
        system = system,
        G = Cond,
        path = path,
    )

end

function calc_conductance_Φ(name::String)
    system = systems[name]

    @unpack Φrng_PD, ωrng, Zs, χs, kBT, outdir = system.calc_params

    path = "$(outdir)/Conductance_Phi/$(name).jld2"
    mkpath(dirname(path))

    Cond = pfunction(
        (Φ, ω, Z, χ) -> try
            g = build_NS(system.params_wire, χ)
            G = conductance(g[2, 2]; nambu = true)
            G(ω; ω, Φ, Z, χ, τ = tau(χ))
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

    if kBT > 0
        # ωrng is complex (ω + iη) for Green-function stability. Thermal broadening acts on real bias.
        ωvals = real.(ωrng)

        # If energies are provided only on [-ωmax, 0], mirror them to [-ωmax, +ωmax]
        # before convolution so broadening near zero does not suffer edge truncation.
        one_sided = maximum(ωvals) <= 0 && minimum(ωvals) < 0

        if one_sided
            ωvals_sym = vcat(ωvals, -reverse(ωvals)[2:end])
            planT = thermal_broadening_plan(ωvals_sym, kBT)

            for (Z, CZ) in pairs(Cond)
                CT = Matrix{Float64}(undef, size(CZ))
                for iΦ in axes(CZ, 1)
                    row = @view CZ[iΦ, :]
                    row_sym = vcat(row, reverse(row)[2:end])
                    rowT_sym = thermal_broaden_conductance(row_sym, planT)
                    @views CT[iΦ, :] .= rowT_sym[1:length(ωvals)]
                end
                Cond[Z] = CT
            end
        else
            planT = thermal_broadening_plan(ωvals, kBT)
            for (Z, CZ) in pairs(Cond)
                CT = Matrix{Float64}(undef, size(CZ))
                for iΦ in axes(CZ, 1)
                    @views CT[iΦ, :] .= thermal_broaden_conductance(CZ[iΦ, :], planT)
                end
                Cond[Z] = CT
            end
        end
    end

    return Results(
        system = system,
        G = Cond,
        path = path,
    )

end