# # Script de prueba para tipos que especifican variantes de simulación
using DrWatson
@quickactivate "HEMI"

using Distributed
# Agregar procesos trabajadores
addprocs(4, exeflags="--project")

# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

gtdata_eval = gtdata[Date(2020, 12)]

resamplefn = ResampleSBB(36)
#resamplefn2 = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk()
savepath = datadir("Trimmed_Mean", "EQ", "SBB36")


sims = Vector{Dict{Symbol,Any}}()
rango_inf = LinRange(0,30,61)
rango_sup = LinRange(70,100,61)
for i in rango_inf
    for j in rango_sup
        inflfn  = InflationTrimmedMeanEq(i,j)
        config  = SimConfig(inflfn, resamplefn, trendfn, 100)
        dict    = struct2dict(config) 
        push!(sims,dict)
    end
end

run_batch(gtdata_eval, sims, savepath)

df = collect_results(savepath)

minimum(df[!,"mse"])

sorted_df = sort(df, "mse")

X = [x[1] for x in df[!,:params]]
Y = [x[2] for x in df[!,:params]]
Z = [x for x in df[!,:mse]]

using Gadfly
using ColorSchemes
#using LaTeXStrings
color_scheme = Scale.ContinuousColorScale(p -> get(ColorSchemes.sunset, p))
plot1 = Gadfly.plot(x=X, y=Y, color=exp.(1 ./ Z), 
        Geom.rectbin, 
        color_scheme, 
        Coord.cartesian(ymin=rango_sup[1],ymax=rango_sup[end],
            xmin=rango_inf[1],xmax=rango_inf[end]), 
        Guide.xlabel("l1"), Guide.ylabel("l2"), 
        Guide.title("MSE"),
        Guide.colorkey(title="Exp(1/MSE)"))

#Gadfly.plot(x=X,y=Y,z=Z, Geom.contour(levels=500), color_scheme)