using DrWatson
@quickactivate "HEMI"

## Cargar datos de la base 2006 
using Dates, CSV, DataFrames
using CPIDataBase

# Base 2006 que empieza en dic-09
nic_base06 = CSV.read(datadir("nicaragua", "Nicaragua_IPC_2006.csv"), 
    DataFrame, normalizenames=true)
nic06gb = CSV.read(datadir("nicaragua", "Nicaragua_GB_2006.csv"), 
    DataFrame, types=[String, String, Float64])

full_nic06 = FullCPIBase(nic_base06, nic06gb)
nic06 = VarCPIBase(full_nic06)

## Guardar datos para su carga posterior
using JLD2

@save datadir("nicaragua", "nicadata.jld2") nic06

nicadata = CountryStructure(nic06)

totalfn = TotalCPI()
tray_infl_nic = totalfn(nicadata)
