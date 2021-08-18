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
grid_batch(gtdata,InflationTrimmedMeanEq, ResampleSBB(36),
            TrendRandomWalk(),10_000, 45:75, 70:100,InflationTotalRebaseCPI(60),
            Date(2019,12);esc="Esc-D"
)

grid_batch(gtdata,InflationTrimmedMeanWeighted, ResampleSBB(36),
            TrendRandomWalk(),10_000, 5:35, 70:100,InflationTotalRebaseCPI(60),
            Date(2019,12);esc="Esc-D"
)

grid_batch(gtdata,InflationTrimmedMeanEq, ResampleSBB(36),
            TrendRandomWalk(),10_000, 45:75, 70:100,InflationTotalRebaseCPI(60),
            Date(2020,12);esc="Esc-D"
)

grid_batch(gtdata,InflationTrimmedMeanWeighted, ResampleSBB(36),
            TrendRandomWalk(),10_000, 5:35, 70:100,InflationTotalRebaseCPI(60),
            Date(2020,12);esc="Esc-D"
)

grid_batch(gtdata,InflationTrimmedMeanEq, ResampleSBB(36),
            TrendRandomWalk(),10_000, 45:75, 70:100,InflationTotalRebaseCPI(36,2),
            Date(2019,12);esc="Esc-D"
)

grid_batch(gtdata,InflationTrimmedMeanWeighted, ResampleSBB(36),
            TrendRandomWalk(),10_000, 5:35, 70:100,InflationTotalRebaseCPI(36,2),
            Date(2019,12);esc="Esc-D"
)

grid_batch(gtdata,InflationTrimmedMeanEq, ResampleSBB(36),
            TrendRandomWalk(),10_000, 45:75, 70:100,InflationTotalRebaseCPI(36,2),
            Date(2020,12);esc="Esc-D"
)

grid_batch(gtdata,InflationTrimmedMeanWeighted, ResampleSBB(36),
            TrendRandomWalk(),10_000, 5:35, 70:100,InflationTotalRebaseCPI(36,2),
            Date(2020,12);esc="Esc-D"
)





# Optimizar
dir_list = ["InflationTrimmedMeanEq\\Esc-D\\MTEq_SBB36_RW_Rebase60_N10000_2019-12", 
            "InflationTrimmedMeanEq\\Esc-D\\MTEq_SBB36_RW_Rebase60_N10000_2020-12", 
            "InflationTrimmedMeanEq\\Esc-D\\MTEq_SBB36_RW_Rebase36_N10000_2019-12", 
            "InflationTrimmedMeanEq\\Esc-D\\MTEq_SBB36_RW_Rebase36_N10000_2020-12",
            "InflationTrimmedMeanWeighted\\Esc-D\\MTW_SBB36_RW_Rebase60_N10000_2019-12",
            "InflationTrimmedMeanWeighted\\Esc-D\\MTW_SBB36_RW_Rebase60_N10000_2020-12",
            "InflationTrimmedMeanWeighted\\Esc-D\\MTW_SBB36_RW_Rebase36_N10000_2019-12",
            "InflationTrimmedMeanWeighted\\Esc-D\\MTW_SBB36_RW_Rebase36_N10000_2020-12"
]

grid_optim(dir_list[1],gtdata,125_000,7 ; esc="Esc-D")
grid_optim(dir_list[2],gtdata,125_000,7 ; esc="Esc-D")
grid_optim(dir_list[3],gtdata,125_000,7 ; esc="Esc-D")
grid_optim(dir_list[4],gtdata,125_000,7 ; esc="Esc-D")
grid_optim(dir_list[5],gtdata,125_000,7 ; esc="Esc-D")
grid_optim(dir_list[6],gtdata,125_000,7 ; esc="Esc-D")
grid_optim(dir_list[7],gtdata,125_000,7 ; esc="Esc-D")
grid_optim(dir_list[8],gtdata,125_000,7 ; esc="Esc-D")