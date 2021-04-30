using DrWatson
@quickactivate "HEMI"

using Dates, CPIDataBase
using JLD2

@load datadir("guatemala", "gtdata32.jld2") gt00 gt10

gtdata = UniformCountryStructure(gt00, gt10)

using InflationFunctions
using BenchmarkTools

perkfn = Percentil(0.72)

perkfn(gtdata);

# Version map
@btime perkfn($gtdata);
# 996.800 μs (247 allocations: 270.09 KiB)

# Version con for
@btime perkfn($gtdata);
# 1.000 ms (247 allocations: 270.09 KiB)

# Version Threads.@threads for 
@btime perkfn($gtdata);
# 1.023 ms (259 allocations: 271.41 KiB) -- 1 thread
# 487.400 μs (269 allocations: 272.41 KiB) -- 2 threads
# 332.800 μs (288 allocations: 274.41 KiB) -- 4 threads

## Distributed computing with threads? 

using Distributed
addprocs(2, exeflags="--project")
@everywhere begin
    using Dates, CPIDataBase
    using InflationEvalTools
    using InflationFunctions
end


@time tray_infl = gentrayinfl(perkfn, gtdata; K = 10_000); 
# 15.044850 seconds (3.02 M allocations: 7.142 GiB, 1.69% gc time) -- 1 worker (main), 2 threads

@time tray_infl = pargentrayinfl(perkfn, gtdata; K = 10_000); 
# 13.154421 seconds (706.78 k allocations: 30.625 MiB) -- 2 workers, 1 thread
# 10.113143 seconds (720.44 k allocations: 30.921 MiB, 0.11% gc time, 0.07% compilation time) -- 2 workers, 2 threads
# 11.936280 seconds (716.47 k allocations: 30.640 MiB, 0.08% gc time) -- 2 workers, 4 threads