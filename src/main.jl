using Pkg, JLD2
include("utilities.jl")
ensure_pkgs(["Quantica", "FullShell", "ProgressMeter", "Parameters", "ArnoldiMethod", "LinearMaps", "FFTW",])
@everywhere begin
    using Quantica, FullShell, QuadGK
    using ProgressMeter, Parameters
    using ArnoldiMethod, LinearMaps, LinearAlgebra
    using FFTW
    using SpecialFunctions, FunctionZeros
    using Suppressor
    
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

if endswith(input, "_mualphaZ")
    name = replace(input, "_mualphaZ" => "")
    @info "Calculating PD for $(name) as a function of μ, α and Z"
    res = calc_PD_mu_alpha_Z(name)
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

if endswith(input, "_muB")
    name = replace(input, "_muB" => "")
    @info "Calculating PD for $(name) as a function of μ and B"
    res = calc_PD_mu_B(name)
    @info "Saving results to $(res.path)"
    save(res.path, "res", res)
    exit(0)
end

if endswith(input, "_flux")
    name = replace(input, "_flux" => "")
    @info "Calculating PD for $(name) as a function of Φ"
    res = calc_PD_flux(name)
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

if endswith(input, "_doschi")
    name = replace(input, "_doschi" => "")
    @info "Calculating DOS vs χ for $(name)"
    res = calc_DOS_chi(name)
    @info "Saving results to $(res.path)"
    save(res.path, "res", res)
    exit(0)
end

if endswith(input, "_ldos")
    name = replace(input, "_ldos" => "")
    @info "Calculating LDOS for $(name)"
    res = calc_LDOS(name)
    @info "Saving results to $(res.path)"
    save(res.path, "res", res)
    exit(0)
end

if endswith(input, "_wfs")
    rmprocs(workers()[3:end])
    name = replace(input, "_wfs" => "")
    @info "Calculating wavefunctions for $(name)"
    res = calc_wfs(name)
    @info "Saving results to $(res.path)"
    save(res.path, "res", res)
    exit(0)
end

if endswith(input, "_ldosvB")
    name = replace(input, "_ldosvB" => "")
    @info "Calculating LDOS for $(name)"
    res = calc_LDOS_vB(name)
    @info "Saving results to $(res.path)"
    save(res.path, "res", res)
    exit(0)
end

if endswith(input, "_conductance")
    name = replace(input, "_conductance" => "")
    @info "Calculating conductance for $(name)"
    res = calc_conductance(name)
    @info "Saving results to $(res.path)"
    save(res.path, "res", res)
    exit(0)
end

if endswith(input, "_conductancePhi")
    name = replace(input, "_conductancePhi" => "")
    @info "Calculating conductance vs flux for $(name)"
    res = calc_conductance_Φ(name)
    @info "Saving results to $(res.path)"
    save(res.path, "res", res)
    exit(0)
end

if endswith(input, "_conductanceTau")
    name = replace(input, "_conductanceTau" => "")
    @info "Calculating conductance vs τ for $(name)"
    res = calc_conductance_τ(name)
    @info "Saving results to $(res.path)"
    save(res.path, "res", res)
    exit(0)
end

@error "Key '$input' not found."