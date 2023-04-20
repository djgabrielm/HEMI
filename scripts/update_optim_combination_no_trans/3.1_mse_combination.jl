using DrWatson
@quickactivate "HEMI" 

using HEMI 

## Parallel processing
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Otras librerías
using DataFrames, Chain


# DEFINIMOS PATHS
loadpath = datadir("results", "no_trans","tray_infl","mse")


combination_savepath  = datadir("results","no_trans","optim_combination","mse")

data_loadpath = datadir("results", "no_trans", "data", "NOT_data.jld2")

#CARGAMOS DATA A EVALUAR
NOT_GTDATA = load(data_loadpath, "NOT_GTDATA")

gtdata_eval = NOT_GTDATA[Date(2021, 12)]


#CREAMOS UNA FUNCION PARA ORDENAR LAS FUNCIONES
function rank(inflfn::InflationFunction)
    if inflfn isa InflationPercentileEq
        return 1
    elseif inflfn isa InflationPercentileWeighted
        return 2
    elseif inflfn isa InflationTrimmedMeanEq
        return 3
    elseif inflfn isa InflationTrimmedMeanWeighted
        return 4
    elseif inflfn isa InflationDynamicExclusion
        return 5
    elseif inflfn isa InflationFixedExclusionCPI
        return 6
    end
end


# CARGAMOS Y ORDENAMOS DATAFRAMES SEGUN LA MEDIDA DE INFLACION
df_results_B00 = collect_results(joinpath(loadpath,"B00"))
df_results_B10 = collect_results(joinpath(loadpath,"B10"))

df_results_B00.rank = rank.(df_results_B00.inflfn)
df_results_B10.rank = rank.(df_results_B00.inflfn)

sort!(df_results_B00, :rank)
sort!(df_results_B10, :rank)


# PATHS DE TRAYECTORIAS
df_results_B00.tray_path = map(x->joinpath(loadpath,"B00","tray_infl",basename(x)),df_results_B00.path)
df_results_B10.tray_path = map(x->joinpath(loadpath,"B10","tray_infl",basename(x)),df_results_B10.path)

# TRAYECTORIAS
tray_infl_B00 = mapreduce(hcat, df_results_B00.tray_path) do path
    load(path, "tray_infl")
end

tray_infl_B10 = mapreduce(hcat, df_results_B10.tray_path) do path
    load(path, "tray_infl")
end


# DEFINIMOS PARAMETRO
resamplefn = df_results_B00.resamplefn[1]
trendfn = df_results_B00.trendfn[1]
paramfn = df_results_B00.paramfn[1] #InflationTotalRebaseCPI(36, 3)
param = InflationParameter(paramfn, resamplefn, trendfn)
tray_infl_pob = param(gtdata_eval)


# FILTRAMOS EXCLUSION FIJA
functions_B00 = df_results_B00.inflfn
components_mask_B00 = [!(fn isa InflationFixedExclusionCPI) for fn in functions_B00]

functions_B10 = df_results_B10.inflfn
components_mask_B10 = [!(fn isa InflationFixedExclusionCPI) for fn in functions_B10]

#####################################
### COMBINACION OPTIMA BASE 2000 y 2010


# DEFINIMOS PERIODOS DE COMBINACION
combine_period_00 =  GT_EVAL_B00 #EvalPeriod(Date(2001, 12), Date(2010, 12), "combperiod_B00") 
combine_period_10 =  GT_EVAL_B10 #EvalPeriod(Date(2011, 12), Date(2021, 12), "combperiod_B10") 

periods_filter_00 = eval_periods(gtdata_eval, combine_period_00)
periods_filter_10 = eval_periods(gtdata_eval, combine_period_10)

# CALCULAMOS LOS PESOS OPTIMOS
a_optim_00 = share_combination_weights(
    tray_infl_B00[periods_filter_00, components_mask_B00, :],
    tray_infl_pob[periods_filter_00],
    show_status=true
)

a_optim_10 = share_combination_weights(
    tray_infl_B10[periods_filter_10, components_mask_B10, :],
    tray_infl_pob[periods_filter_10],
    show_status=true
)

# Insertamos el 0 en el vector de pesos en el lugar correspondiente a exclusion fija
insert!(a_optim_00, findall(.!components_mask_B00)[1],0)
insert!(a_optim_10, findall(.!components_mask_B10)[1],0)

# CREAMOS SUBYACENTES OPTIMAS PARA CADA BASE
optmseb00 = CombinationFunction(
    functions_B00...,
    a_optim_00, 
    "Subyacente óptima MSE no transable base 2000"
)

optmseb10 = CombinationFunction(
    functions_B10...,
    a_optim_10, 
    "Subyacente óptima MSE no transable base 2010"
)

# EMPALMAMOS LA FUNCION PARA CREAR UNA SUBYACENTE OPTIMA NO TRANSABLE
optmse2023_nt = Splice([optmseb00, optmseb10], [(Date(2011,01), Date(2011,11))], "Subyacente Óptima MSE 2023 No Transable", "SubOptMse2023NT")

# GUARDAMOS  
wsave(joinpath(combination_savepath,"optmse2023_nt.jld2"), "optmse2023_nt", optmse2023_nt)


# using PrettyTables
# pretty_table(DataFrame(
#        measure  = [measure_name(x) for x in optmseb00.ensemble.functions],
#        wheights = optmseb00.weights
#        )
# )
# ┌───────────────────────────────────────────────┬─────────────┐
# │                                       measure │    wheights │
# │                                        String │     Float32 │
# ├───────────────────────────────────────────────┼─────────────┤
# │                  Percentil equiponderado 72.0 │ 0.000305138 │
# │                      Percentil ponderado 69.0 │    0.159912 │
# │     Media Truncada Equiponderada (21.0, 96.0) │    0.564511 │
# │         Media Truncada Ponderada (24.0, 97.0) │    0.201096 │
# │    Inflación de exclusión dinámica (0.8, 3.7) │   0.0741767 │
# │ Exclusión fija de gastos básicos IPC (13, 21) │         0.0 │
# └───────────────────────────────────────────────┴─────────────┘

# pretty_table(DataFrame(
#        measure  = [measure_name(x) for x in optmseb10.ensemble.functions],
#        wheights = optmseb10.weights
#        )
# )

# ┌───────────────────────────────────────────────┬────────────┐
# │                                       measure │   wheights │
# │                                        String │    Float32 │
# ├───────────────────────────────────────────────┼────────────┤
# │                  Percentil equiponderado 76.0 │ 6.20741e-7 │
# │                      Percentil ponderado 74.0 │  0.0315446 │
# │     Media Truncada Equiponderada (43.0, 95.0) │   0.792103 │
# │         Media Truncada Ponderada (42.0, 97.0) │   0.176352 │
# │    Inflación de exclusión dinámica (0.3, 2.8) │ 1.81102e-7 │
# │ Exclusión fija de gastos básicos IPC (13, 21) │        0.0 │
# └───────────────────────────────────────────────┴────────────┘

######################################################################################
################## INTERVALO DE CONFIANZA ############################################
######################################################################################


## CREACION DE TRAYECTORIAS DE OPTIMA MSE 
inf_dates = infl_dates(gtdata_eval)
ramp_down = CPIDataBase.ramp_down(inf_dates, Date(2011,01), Date(2011,11)) 
ramp_up = CPIDataBase.ramp_up(inf_dates, Date(2011,01), Date(2011,11))

w_tray_B00 = sum(a_optim_00' .* tray_infl_B00, dims=2)
w_tray_B10 = sum(a_optim_10' .* tray_infl_B10, dims=2)

w_tray = ramp_down .* w_tray_B00 .+ ramp_up .* w_tray_B10

## ERRORES
b = reshape(tray_infl_pob,(length(tray_infl_pob),1,1))
error_tray = dropdims(w_tray .- b,dims=2)

## PERIODOS DE EVALUACION
period_b00 = EvalPeriod(Date(2001,12), Date(2010,12), "b00")
period_trn = EvalPeriod(Date(2011,01), Date(2011,11), "trn")
period_b10 = EvalPeriod(Date(2011,12), Date(2021,12), "b10")

b00_mask = eval_periods(gtdata_eval, period_b00)
trn_mask = eval_periods(gtdata_eval, period_trn)
b10_mask = eval_periods(gtdata_eval, period_b10)

tray_b00 = error_tray[b00_mask, :]
tray_trn = error_tray[trn_mask, :]
tray_b10 = error_tray[b10_mask, :]


## CUANTILES
quant_0125 = quantile.(vec.([tray_b00,tray_trn,tray_b10]),0.0125)  
quant_9875 = quantile.(vec.([tray_b00,tray_trn,tray_b10]),0.9875) 

bounds =transpose(hcat(-quant_0125,-quant_9875))

# pretty_table(hcat(["upper","lower"],bounds),["","b00","T","b10"])
# ┌───────┬──────────┬───────────┬───────────┐
# │       │      b00 │         T │       b10 │
# ├───────┼──────────┼───────────┼───────────┤
# │ upper │  1.56475 │   1.36485 │  0.415282 │
# │ lower │ -1.37589 │ -0.738597 │ -0.437598 │
# └───────┴──────────┴───────────┴───────────┘
