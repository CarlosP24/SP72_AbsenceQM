using Pkg, JLD2
include("utilities.jl")
ensure_pkgs(["Quantica", "FullShell", "ProgressMeter", "Parameters"])
@everywhere begin
    using Quantica, FullShell
    using ProgressMeter, Parameters
    using LinearAlgebra, Arpack
    BLAS.set_num_threads(1)

    # Load
    include("utilities.jl")
    include_all("builders")
    include_all("operators")
    include_all("parallelizers")
    include("models/models.jl")
    include_all("calculations")
end
## Run 
input = ARGS[1]

if endswith(input, "_mualpha")
    name = replace(input, "_mualpha" => "")
    @info "Calculating PD for $(name) as a function of μ and α"
    res = calc_PD_mu_alpha(name)
    @info "Saving results to $(res.path)"
    save(res.path, "res", res)
    exit(0)
end

if endswith(input, "_muflux")
    name = replace(input, "_muflux" => "")
    @info "Calculating PD for $(name) as a function of μ and Φ"
    res = calc_PD_mu_flux(name)
    @info "Saving results to $(res.path)"
    save(res.path, "res", res)
    exit(0)
end

if endswith(input, "_dos")
    name = replace(input, "_dos" => "")
    @info "Calculating DOS for $(name)"
    res = calc_DOS(name)
    @info "Saving results to $(res.path)"
    save(res.path, "res", res)
    exit(0)
end

@error "Key '$input' not found."