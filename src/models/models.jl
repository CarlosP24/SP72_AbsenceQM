@with_kw struct Calc_Params
    αrng = range(0, 50, length = 400)
    μrng = range(0, 50, length = 400)
    Φrng = range(0.501, 1.499, length = 201)
    ωrng = range(-0.26, 0, length = 201) .+ 1e-3im
    Zs = [0]
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
    params_wire::Params = Params()
    calc_params::Calc_Params = Calc_Params()
end

include("fullshells.jl")

systems = full_shells

