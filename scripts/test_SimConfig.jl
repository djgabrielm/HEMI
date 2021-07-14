# # Script de prueba para tipos que especifican variantes de simulación
using DrWatson
@quickactivate "HEMI"

# ## Cargamos paquete de evaluación
using HEMI


## Obtener un ejemplo 
# Parámetros de simulación
totalfn = InflationTotalCPI()
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk()
ff = Date(2020, 12)
sz = 24
# Exclusión Fija
excOpt00 = [35,30,190,36,37,40,31,104,162,32,33,159,193,161]
excOpt10 = [29,31,116,39,46,40,30,35,186,47,197,41,22,48,185,34,184]
fxEx = InflationFixedExclusionCPI(excOpt00, excOpt10)

## Crear una configuración de pruebaa 
configA = SimConfig(totalfn, resamplefn, trendfn, 10000)
configB = CrossEvalConfig(totalfn, resamplefn, trendfn, 1000, ff, sz)
configC = SimConfig(fxEx, resamplefn, trendfn, 10000)
## Mostrar el nombre generado por la configuración 
savename(configA, connector=" | ", equals=" = ")
savename(configB, connector=" | ", equals=" = ")
savename(configC, connector=" | ", equals=" = ")

## Conversión de AbstractConfig a Diccionario

dic_a = convert_dict(configA)
dic_b = convert_dict(configB)
dic_c = convert_dict(configC)

# Función evalsim 
gtdata_eval = gtdata[Date(2020, 12)]

evalsim(gtdata_eval, configA)

makesim(gtdata_eval, configA)

##
gsbb_perc_params = Dict(
    "infl_method" => "percentil", 
    "resample_method" => "gsbb", 
    "k" => collect(60:80), 
    "b" => 0, 
    "Ksim" => [10_000, 125_000]
) |> dict_list

dict_prueba = Dict(
    :inflfn => totalfn, 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :nsim => 10_000)

dict_pruebaB = Dict(
    :inflfn => totalfn, 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :nsim => 10_000,
    :train_date => ff,
    :eval_size => sz)

    
    configD = SimConfig(dict_prueba[:inflfn], dict_prueba[:resamplefn], dict_prueba[:trendfn], dict_prueba[:nsim])    

    configD_a = dict_config(dict_prueba)
    configE = dict_config(dict_pruebaB)