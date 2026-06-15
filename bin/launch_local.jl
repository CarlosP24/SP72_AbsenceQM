using Distributed
addprocs(8)

@everywhere begin
    using Pkg; Pkg.activate(".");
    Pkg.instantiate(); Pkg.precompile()
end 

## Run code and always clean up workers
try
    include("../src/main.jl")
finally
    ws = workers()
    !isempty(ws) && rmprocs(ws...)
end