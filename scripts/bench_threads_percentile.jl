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

# 796.200 μs (259 allocations: 271.41 KiB) -- BG 1 thread
# 403.200 μs (269 allocations: 272.41 KiB) -- BG 2 threads

## Distributed computing with threads? 

using Distributed
addprocs(4, exeflags="--project")
@everywhere begin
    using Dates, CPIDataBase
    using InflationEvalTools
    using InflationFunctions
end


@time tray_infl = gentrayinfl(perkfn, gtdata; K = 10_000); 
# 15.044850 seconds (3.02 M allocations: 7.142 GiB, 1.69% gc time) -- 1 worker (main), 2 threads
# 16.590934 seconds (2.91 M allocations: 7.132 GiB, 3.08% gc time) -- BG 1 worker (main), 1 thread
# 13.591727 seconds (3.02 M allocations: 7.142 GiB, 2.42% gc time) -- BG 1 worker (main), 2 threads

@time tray_infl = pargentrayinfl(perkfn, gtdata; K = 10_000); 
# 13.154421 seconds (706.78 k allocations: 30.625 MiB) -- 2 workers, 1 thread
# 10.113143 seconds (720.44 k allocations: 30.921 MiB, 0.11% gc time, 0.07% compilation time) -- 2 workers, 2 threads
# 11.936280 seconds (716.47 k allocations: 30.640 MiB, 0.08% gc time) -- 2 workers, 4 threads

# 5.222101 seconds (858.92 k allocations: 39.195 MiB, 0.19% gc time, 0.58% compilation time) -- BG 4 workers, 1 thread
# 4.188488 seconds (712.21 k allocations: 30.564 MiB, 0.22% gc time) -- BG 4 workers, 2 threads
# 3.996098 seconds (711.16 k allocations: 30.535 MiB, 0.21% gc time) -- BG 5 workers, 2 threads

allpercfn = Percentil.(0.65:0.01:0.80) |> Tuple |> EnsembleFunction 

allpercfn(gtdata); 


@time tray_infl = pargentrayinfl(perkfn, gtdata; K = 125_000); 
# 50.646876 seconds (8.87 M allocations: 380.705 MiB, 0.15% gc time) -- BG 5 workers, 2 threads

@time tray_infl = pargentrayinfl(allpercfn, gtdata; K = 125_000); 
# 366.145377 seconds (9.05 M allocations: 390.155 MiB, 0.03% gc time) -- BG 4 workers, 2 threads
# 343.133883 seconds (9.04 M allocations: 389.522 MiB, 0.02% gc time) -- BG 5 workers, 2 threads