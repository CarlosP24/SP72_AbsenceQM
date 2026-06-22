@with_kw struct Calc_Params
    αrng = range(0, 50, length = 500)
    μrng = range(0, 60, length = 500)
    μrngP = range(-4, 4, length = 200)
    Φrng_PD = range(0.501, 1.499, length = 501)
    Φrng_DOS = range(0, 2.499, length = 301)
    ωrng = range(-0.26, 0, length = 301) .+ 1e-3im
    Brng = range(0, 5; length = 501)
    χrng = 10 .^range(0, 3.5, length = 300)
    #Φs = [0.7, 0.9]
    Φs = [0.65, 0.88]
    Bs = [1.5 * 2, 0.9 * 2]
    NDOS = 5
    Vdis = 0
    Zs = [0]
    χ = "default"
    χs = [5, 1000]
    kBT = 0.0
    outdir = "data"
end

@with_kw struct Results 
    system = nothing
    LDOS = nothing
    DOS = nothing
    PD = nothing
    Psis = nothing
    G = nothing
    path = nothing
end

@with_kw struct Params_System
    params_wire::Union{Params, Params_Partial} = Params()
    calc_params::Calc_Params = Calc_Params()
end

include("fullshells.jl")
include("partials.jl")

systems = merge(full_shells, partials)

