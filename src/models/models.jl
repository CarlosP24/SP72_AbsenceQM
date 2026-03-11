@with_kw struct Calc_Params
    αrng = range(0, 50, length = 500)
    μrng = range(0, 60, length = 500)
    μrngP = range(-4, 4, length = 200)
    Φrng_PD = range(0.501, 1.499, length = 501)
    Φrng_DOS = range(0, 2.499, length = 101)
    ωrng = range(-0.26, 0, length = 101) .+ 1e-3im
    Brng = range(0, 5; length = 501)
    NDOS = 5
    Zs = [0]
    χ = "default"
    outdir = "data"
end

@with_kw struct Results 
    system = nothing
    LDOS = nothing
    DOS = nothing
    PD = nothing
    path = nothing
end

@with_kw struct Params_System
    params_wire::Union{Params, Params_Partial} = Params()
    calc_params::Calc_Params = Calc_Params()
end

include("fullshells.jl")
include("partials.jl")

systems = merge(full_shells, partials)

