using Optim
using DataFrames
using JLD2


function grid_optim(data_dir, data, N::Int64, radius, measure=:mse; save_dir="")
                df          = collect_results(datadir(data_dir))
                bitarray    = (!).(ismissing.(df[:,measure]) .|  isnan.(df[:,measure]))
                df          = df[bitarray, :]
                condition   =  measure==:corr   
                sorted_df   = sort(df,measure, rev=condition)
                min_params  = sorted_df[1,:params]
                inflfn      = typeof(sorted_df[1,:inflfn])
                resamplefn  = sorted_df[1,:resamplefn]
                trendfn     = sorted_df[1,:trendfn]
                paramfn     = sorted_df[1,:paramfn]
                traindate   = sorted_df[1,:traindate]
                initial_params = [x for x in min_params]
                lower_b     = max.(initial_params .- radius, 0.0f0)
                upper_b     = min.(initial_params .+ radius, 100.0f0)
                f = x -> evaltrim(x, inflfn, resamplefn, trendfn, data, paramfn, traindate; K = N, measure,lb=lower_b, ub=upper_b)
                optres = optimize(f, lower_b, upper_b, initial_params, NelderMead(), Optim.Options(iterations=100, g_tol=1.0e-3))
                min_params = optres.minimizer
                INF         = inflfn(min_params)
                config      = SimConfig(INF, resamplefn, trendfn, paramfn, N, traindate)
                results, _  = makesim(gtdata, config)
                filename    = savename(config, "jld2")
                savepath    = datadir(save_dir, "optim")
                wsave(joinpath(savepath, filename), tostringdict(results))

end


function evaltrim(k, inflfn ,resamplefn, trendfn, evaldata, paramfn , traindate ;
                     K = 10_000, measure=:mse, lb=zeros(length(k)),ub=100*ones(length(k)))
    # Crear configuración de evaluación
    if k[1]< k[2]
        if lb[1]<k[1]<ub[1] && lb[2]<k[2]<ub[2]
        evalconfig = SimConfig(
            inflfn = inflfn(k),
            resamplefn = resamplefn, 
            trendfn = trendfn, 
            paramfn = paramfn,
            nsim = K,
            traindate = traindate)

        # Evaluar la medida y obtener el MSE
        results, _ = makesim(evaldata, evalconfig)
        out = results[measure]
        return out*(-1)^Int(measure==:corr)
        end
    end
    return 1.0e5
end



#Ejemplo

#grid_optim(dir, gtdata,10000,4, :mse)

#g = x -> grid_optim(x, gtdata,1000,4, :mse)
#g.(dir_list)