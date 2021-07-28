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
savepath = datadir("Trimmed_Mean", "Weighted", "SBB36","nsim10000")


sims = Vector{Dict{Symbol,Any}}()
rango_inf = LinRange(0,40,41)
rango_sup = LinRange(60,100,41)
for i in rango_inf
    for j in rango_sup
        inflfn  = InflationTrimmedMeanWeighted(i,j)
        config  = SimConfig(inflfn, resamplefn, trendfn, 10000)
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

ARRAY = collect(zip(X,Y,Z))
sort!(ARRAY,by=x->x[2])
sort!(ARRAY,by=x->x[1])
ARRAY2 = reshape(ARRAY,length(rango_sup),length(rango_inf)) 
MATRIX = [x[3] for x in ARRAY2]

using Plots
using LaTeXStrings
plot1 = heatmap(rango_inf,
            rango_sup, 
            (1 ./ MATRIX), 
            title  = L"MSE^{-1} \ para \ media \ truncada \  ponderada \ con \ SBB(36) \ y \ N_{sim} = 10,000 ",
            xlabel = L"\ell_1", 
            ylabel = L"\ell_2",
            size   = (600,400),
            titlefontsize = 10
            )

cd(plotsdir("Trimmed_Mean", "Weighted", "SBB36", "nsim10000"))
savefig(plot1, "plot1.png") #tambien se puede guardar en .svg
savefig(plot1, "plot1.svg") 

