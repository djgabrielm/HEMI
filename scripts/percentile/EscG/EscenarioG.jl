using DrWatson
@quickactivate "HEMI"
using Plots
using DataFrames
using Chain
using PrettyTables


## Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
addprocs(4, exeflags="--project")
# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

#= 
inflfn1 = InflationPercentileEq.(0:0.001:1)
inflfn2 = InflationPercentileWeighted.(0:0.001:1)
resamplefn = ResampleScrambleVarMonths() 
trendfn = TrendRandomWalk()
paramfn = InflationTotalRebaseCPI(36, 2)
gtdata_eval = gtdata[Date(2018, 12)]
ff = Date(2018, 12)
N = 1_000

save_dirs = [datadir("results","PercEq","Esc-G","PercEq_SVM_RW_Rebase36_N1000_2018-12"),
             datadir("results","PercW","Esc-G","PercW_SVM_RW_Rebase36_N1000_2018-12")
]

dict_percEq = Dict(
    :inflfn => inflfn1, 
    :resamplefn => resamplefn,
    :trendfn => trendfn,
    :paramfn => paramfn,
    :nsim => N,
    :traindate => ff
) |> dict_list 

dict_percW = Dict(
    :inflfn => inflfn2, 
    :resamplefn => resamplefn,
    :trendfn => trendfn,
    :paramfn => paramfn,
    :nsim => N,
    :traindate => ff
) |> dict_list 

#run_batch(gtdata_eval, dict_percEq, save_dirs[1]; savetrajectories = false)
#run_batch(gtdata_eval, dict_percW, save_dirs[2]; savetrajectories = false)

df1 = collect_results(save_dirs[1])
df2 = collect_results(save_dirs[2])

=#

include(scriptsdir("percentile","perc-optimization.jl"))

variants_dict = dict_list(Dict(
    :infltypefn => [InflationPercentileEq, InflationPercentileWeighted],
    :resamplefn => ResampleScrambleVarMonths() ,
    :trendfn => TrendRandomWalk(),
    :paramfn => InflationTotalRebaseCPI(60),
    :nsim => 10_000,
    :traindate => Date(2018, 12))
)

savepath = datadir("results", "Percentile", "Esc-G", "Optim")

using Optim

for config in variants_dict
    optimizeperc(config, gtdata; savepath, maxiterations = 50, kbounds = [0.00001, 0.99999], measure = :absme)
end


