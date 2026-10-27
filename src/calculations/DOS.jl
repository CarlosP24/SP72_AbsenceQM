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

# m_J = 0 DOS of the smooth end vs (χ, ω) at the quasi-MZM flux Φs[2] (same sampling as
# calc_DOS). ωrng may carry a broadening ∝ |ω| (log grid), so that a bound state shows up as a
# sharp peak at any energy scale. Tasks are (χ, chunk of ωrng): g is built once per task.
# pref: smooth region of length pref·χ before the bulk. The default log(100) cuts the full-shell
# profile at 4.6χ, inside the Φ^(2) topological segment (3.5χ–7χ): use pref ≥ 10 for the pair.
function calc_DOS_vchi(name::String; nchunks = 6, pref = log(100))
    system = systems[name]
    @unpack χrng, ωrng, Φs, NDOS, outdir = system.calc_params
    path = "$(outdir)/DOS_vchi/$(name).jld2"
    mkpath(dirname(path))

    params_wire = system.params_wire
    ωs = collect(ωrng)
    chunks = [ωs[k:nchunks:end] for k in 1:nchunks]

    parts = pfunction(
        (χ, k) -> try
            g, L = greens_softwire(params_wire, χ; pref)
            a0 = params_wire.a0
            N = round(Int, L / a0)
            step = max(1, round(Int, N / NDOS))
            ρ = ldos(g[region = r -> r[1] in Set(x * a0 for x in 0:step:N)]; kernel = I)
            [ρ(ω; ω, Φ = Φs[2], Z = 0) |> sum for ω in chunks[k]]
        catch e
            @warn "Error calculating DOS at (χ=$χ, chunk=$k): $e"
            fill(NaN, length(chunks[k]))
        end,
        [χrng, 1:nchunks];
    )
    DOS = zeros(length(χrng), length(ωs))
    for i in eachindex(χrng), k in 1:nchunks
        DOS[i, k:nchunks:end] .= parts[i, k]
    end

    return Results(
        system = system,
        DOS = Dict("QMajo" => DOS),
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