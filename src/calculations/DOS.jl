function calc_DOS(name::String)
    system = systems[name]
    if system.params_wire isa Params_Partial
        res = calc_DOS_B(name)
        return res
    end

    @unpack Φrng_DOS, ωrng, Zs, NDOS, χ, outdir = system.calc_params
    # Output path
    path = "$(outdir)/DOS/$(name).jld2"
    mkpath(dirname(path))

    g, L = greens_softwire(system.params_wire, χ)
    a0 = system.params_wire.a0
    N = round(Int, L / a0)
    step = max(1, round(Int, N / NDOS))
    positions = [x * a0 for x in 0:step:N]
    ρ = ldos(g[region = r -> r[1] in Set(positions)]; kernel = I)

    DOS = pfunction(
        (Φ, ω, Z) -> try
            ρ(ω; ω, Φ, Z) |> sum
        catch e
            @warn "Error calculating DOS at (Φ=$Φ, ω=$ω, Z=$Z): $e"
            NaN
        end,
        [Φrng_DOS, ωrng, Zs];
    )

    DOS = Dict(
        Z => DOS[:, :, i] for (i, Z) in enumerate(Zs)
    )

    return Results(
        system = system,
        DOS = DOS,
        path = path,
    )
end

function calc_DOS_chi(name::String)
    system = systems[name]

    @unpack χrng, ωrng, Φs, outdir = system.calc_params
    path = "$(outdir)/DOS_chi/$(name).jld2"
    mkpath(dirname(path))

    params_wire = system.params_wire
    nchunks = 50

    full_DOS = pfunction(
        (χ, chunk_idx) -> try
            g, L = greens_softwire(params_wire, χ)
            a0 = params_wire.a0
            N = round(Int, L / a0)
            positions = Set(x * a0 for x in chunk_idx:nchunks:N)
            isempty(positions) && return zeros(length(ωrng), length(Φs))
            ρ = ldos(g[region = r -> r[1] in positions]; kernel = I)
            [ρ(ω; ω, Φ) |> sum for ω in ωrng, Φ in Φs]
        catch e
            @warn "Error calculating DOS at (χ=$χ, chunk=$chunk_idx): $e"
            fill(NaN, length(ωrng), length(Φs))
        end,
        [χrng, 0:nchunks-1];
    )
    # full_DOS is (n_χ × nchunks) array of (n_ω × n_Φ) matrices; sum over chunks
    DOS = zeros(length(χrng), length(ωrng), length(Φs))
    for i in eachindex(χrng), j in 1:nchunks
        DOS[i, :, :] .+= full_DOS[i, j]
    end

    DOS = Dict(
        name => DOS[:, :, i] for (i, name) in enumerate(["Majo", "QMajo"])
    )


    return Results(
        system = system,
        DOS = DOS,
        path = path,
    )
end

function calc_DOS_B(name::String)
    system = systems[name]
    @unpack Brng, ωrng, NDOS, χ, outdir = system.calc_params
    # Output path
    path = "$(outdir)/DOS/$(name).jld2"
    mkpath(dirname(path))

    g, L = greens_softwire(system.params_wire, χ)
    a0 = system.params_wire.a0
    N = round(Int, L / a0)
    step = max(1, round(Int, N / NDOS))
    positions = [x * a0 for x in 0:step:N]
    ρ = ldos(g[region = r -> r[1] in Set(positions)]; kernel = I)

    DOS = pfunction(
        (B, ω) -> try
            ρ(ω; ω, B) |> sum
        catch e
            @warn "Error calculating DOS at (B=$B, ω=$ω): $e"
            NaN
        end,
        [Brng, ωrng];
    )
        
    return Results(
        system = system,
        DOS = DOS,
        path = path,
    )
end