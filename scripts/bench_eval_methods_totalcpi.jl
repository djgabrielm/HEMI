using DrWatson
@quickactivate "HEMI"

## TODO 
# Simulación básica en serie con replicación y benchmark vs MATLAB ✔
# Simulación en paralelo con replicación y benchmark vs MATLAB
# Agregar funciones de inflación adicionales
# ... (mucho más)

using Dates, CPIDataBase
using JLD2
using CPIDataBase.Resample

# Carga de datos
@load datadir("guatemala", "gtdata32.jld2") gt00 gt10
const gtdata = CountryStructure(gt00, gt10)

## Definición de función de simulación

using Random
import CPIDataBase: InflationFunction
using ProgressMeter

function gentrayinfl(inflfn::InflationFunction, csdata::CountryStructure; 
    K = 100, rndseed = 161803, showprogress = true, sub_offset_periods = true)

    # Configurar el generador de números aleatorios
    myrng = MersenneTwister(rndseed)

    # Matriz de trayectorias de salida
    offset = sub_offset_periods ? 11 : 0
    T = sum(size(gtdata[i].v, 1) for i in 1:length(gtdata.base)) - offset
    tray_infl = zeros(Float32, T, K)

    # Control de progreso
    p = Progress(K; enabled = showprogress)

    # Generar las trayectorias
    for k in 1:K 
        # Muestra de bootstrap de los datos 
        bootsample = deepcopy(csdata)
        scramblevar!(bootsample, myrng)

        # Computar la medida de inflación 
        if sub_offset_periods
            tray_infl[:, k] = inflfn(bootsample)
        else
            # Computar inflación in-place
            tray_infl_k = @view tray_infl[:, k]
            inflfn(tray_infl_k, bootsample)
        end
        
        ProgressMeter.next!(p)
    end

    # Retornar las trayectorias
    tray_infl
end

## Benchmark de tiempos
# Función de inflación IPC con capitalización in-place

totalfn = CPIDataBase.TotalEvalCPI()

@time tray_infl = gentrayinfl(totalfn, gtdata; K=10_000)  
# Con TotalCPI: 
# Progress: 100%|██████████████████████████| Time: 0:00:10
#  10.099791 seconds (399.15 k allocations: 4.574 GiB, 1.41% gc time, 0.06% compilation time)

# Con TotalEvalCPI: 
# Progress: 100%|██████████████████████████| Time: 0:00:09
#   9.668163 seconds (374.22 k allocations: 2.330 GiB, 1.34% gc time)

@time tray_infl = gentrayinfl(totalfn, gtdata; K = 125_000)
# Con TotalCPI: 
# julia> @time tray_infl = gentrayinfl(totalfn, gtdata; K = 125000) 
# 136.687623 seconds (4.87 M allocations: 57.170 GiB, 2.85% gc time)

# Con TotalEvalCPI: 
# julia> @time tray_infl = gentrayinfl(totalfn, gtdata; K = 125000) 
# Progress: 100%|██████████████████████████| Time: 0:02:02
# 122.225436 seconds (4.69 M allocations: 29.127 GiB, 1.45% gc time)



## Benchmark de tiempos
# Función de inflación IPC con ahorro de memoria al máximo

totalfn_ex = CPIDataBase.TotalExtremeCPI()
# arr = zeros(Float64, 242)
# totalfn_ex(arr, gtdata)

@time tray_infl = gentrayinfl(totalfn_ex, gtdata; K=10_000, sub_offset_periods = false)  
# Progress: 100%|██████████████████████████| Time: 0:00:09
#   9.978976 seconds (452.44 k allocations: 2.296 GiB, 1.65% gc time, 0.36% compilation time)

@time tray_infl = gentrayinfl(totalfn_ex, gtdata; K=125_000, sub_offset_periods = false)
# Progress: 100%|██████████████████████████| Time: 0:02:03
# 123.314872 seconds (5.18 M allocations: 28.678 GiB, 1.41% gc time)

