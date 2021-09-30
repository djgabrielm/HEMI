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


# Cargamos scripts auxiliares para la optimización.
include(scriptsdir("trimmed_mean","scripts","grid_batch.jl"))
include(scriptsdir("trimmed_mean","scripts","grid_optim.jl"))

## CONFIGURACION ----------------------------------------------------------------------

# Definimos directorios donde se guardan y recolectan datos de este script
# NOTA: no es necesario incluir datadir(), las funciones grid_batch() y grid_optim()
# automáticamente incluyen datadir().
save_dirs = [joinpath("results","InflationTrimmedMeanEq","Esc-F"),
             joinpath("results","InflationTrimmedMeanWeighted","Esc-F")
]

conf1 = [InflationTrimmedMeanEq, ResampleScrambleVarMonths(), TrendRandomWalk(), 
        1_000, 0:100, 0:100, InflationTotalRebaseCPI(36,2), Date(2018,12)
]

conf2 = [InflationTrimmedMeanWeighted, ResampleScrambleVarMonths(), TrendRandomWalk(), 
        1_000, 0:100, 0:100, InflationTotalRebaseCPI(36,2), Date(2018,12)
]

gtdata_eval = gtdata[Date(2018, 12)]


## SIMULACION DE GRILLA ---------------------------------------------------------------
# Simulamos nuestras funciones en un grilla donde el eje X es un rango de valores
# para el límite inferior l1 y el eje Y es un rango de valores para elel límite 
# superior l2 en las funciones de Media Truncada. El objetivo de la grilla es 
# encontrar un punto de arranque para la optimización, debido a que esta utiliza
# un número mucho mayor de simulaciones que la grilla y puede ser muy tardada si no
# le proporcionamos un valor inicial que sea cercano al verdadero óptimo.

grid_batch(gtdata, conf1... ; save_dir = save_dirs[1] )
            
grid_batch(gtdata, conf2... ; save_dir = save_dirs[2] )

## OPTIMIZACION ----------------------------------------------------------------------------
# definimos los directorios donde se encuentran los resultados de la grilla
dir_list = [joinpath(save_dirs[1], alias2(conf1[1:3]..., conf1[7], conf1[4], conf1[8])), 
            joinpath(save_dirs[2], alias2(conf2[1:3]..., conf2[7], conf2[4], conf2[8]))
]

# corremos el script para optimizar, es decir encontrar el punto mínimo para cada
# función, en donde el punto de arranque es el mínimo de la grilla. 
grid_optim(dir_list[1], gtdata_eval, 10_000, 20, :corr; save_dir = save_dirs[1])
grid_optim(dir_list[2], gtdata_eval, 10_000, 20, :corr; save_dir = save_dirs[2])


## GRAFICACION ------------------------------------------------------------------------------------
# definimos los directorios donde se encuentran los resultados de la optimización.
dirs = [joinpath(save_dirs[1],"optim"),
        joinpath(save_dirs[2],"optim")
]

# cargamos los datos
df1 = collect_results(datadir(dirs[1]))
df2 = collect_results(datadir(dirs[2]))
df = vcat(df1,df2)

# Graficamos
p = Plots.plot(InflationTotalCPI(), gtdata, fmt = :svg)
Plots.plot!(df.inflfn[1], gtdata, fmt = :svg)
Plots.plot!(df.inflfn[2], gtdata, fmt = :svg)

# guardamos la imágen en el siguiente directorio
plotpath = joinpath("docs", "src", "eval", "EscF", "images", "trimmed_mean")
Plots.svg(p, joinpath(plotpath, "trayectorias_MT"))
