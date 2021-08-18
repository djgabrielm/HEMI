using DrWatson
using Plots
using DataFrames
using Chain
using PrettyTables
@quickactivate "HEMI"

## Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
addprocs(4, exeflags="--project")

# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

# Cargar scripts auxiliares para optimización
include("../scripts/grid_batch.jl")
include("../scripts/grid_optim.jl")


# Obtener una grilla para las medidas
grid_batch(gtdata,InflationTrimmedMeanEq, ResampleScrambleVarMonths(),
            TrendRandomWalk(),10_000, 45:75, 70:100,InflationTotalRebaseCPI(60),
            Date(2019,12);esc="Esc-C"
)

grid_batch(gtdata,InflationTrimmedMeanWeighted, ResampleScrambleVarMonths(),
            TrendRandomWalk(),10_000, 5:35, 70:100,InflationTotalRebaseCPI(60),
            Date(2019,12);esc="Esc-C"
)

grid_batch(gtdata,InflationTrimmedMeanEq, ResampleScrambleVarMonths(),
            TrendRandomWalk(),10_000, 45:75, 70:100,InflationTotalRebaseCPI(60),
            Date(2020,12);esc="Esc-C"
)

grid_batch(gtdata,InflationTrimmedMeanWeighted, ResampleScrambleVarMonths(),
            TrendRandomWalk(),10_000, 5:35, 70:100,InflationTotalRebaseCPI(60),
            Date(2020,12);esc="Esc-C"
)

# Optimizar
dir_list = ["InflationTrimmedMeanEq\\Esc-C\\MTEq_SVM_RW_Rebase60_N10000_2019-12", 
            "InflationTrimmedMeanEq\\Esc-C\\MTEq_SVM_RW_Rebase60_N10000_2020-12", 
            "InflationTrimmedMeanWeighted\\Esc-C\\MTW_SVM_RW_Rebase60_N10000_2019-12",
            "InflationTrimmedMeanWeighted\\Esc-C\\MTW_SVM_RW_Rebase60_N10000_2020-12"
]

grid_optim(dir_list[1],gtdata,125_000,7 ; esc="Esc-C")
grid_optim(dir_list[2],gtdata,125_000,7 ; esc="Esc-C")
grid_optim(dir_list[3],gtdata,125_000,7 ; esc="Esc-C")
grid_optim(dir_list[4],gtdata,125_000,7 ; esc="Esc-C")

# Separamos entre 2019 y 2020

dirs = ["InflationTrimmedMeanEq\\Esc-C\\optim",
        "InflationTrimmedMeanWeighted\\Esc-C\\optim"
]

df1 = collect_results(datadir("results",dirs[1]))
df2 = collect_results(datadir("results",dirs[2]))

df2020 = vcat(DataFrame(df1[1,:]),DataFrame(df2[1,:]))
df2019 = vcat(DataFrame(df1[2,:]),DataFrame(df2[2,:]))

# Graficamos

p = plot(InflationTotalCPI(), gtdata, fmt = :svg)
plot!(df2019.inflfn[1], gtdata, fmt = :svg)
plot!(df2019.inflfn[2], gtdata, fmt = :svg)