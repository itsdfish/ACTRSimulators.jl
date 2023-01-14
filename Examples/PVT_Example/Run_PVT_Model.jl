###################################################################################################
#                                        Load Packages
###################################################################################################
cd(@__DIR__)
using Pkg
Pkg.activate("../..")
using Revise, ACTRSimulators
import_gui()
import ACTRSimulators: start!, press_key!, repaint!
include("PVT.jl")
include("PVT_Model.jl")
###################################################################################################
#                                        Run Model
###################################################################################################
Random.seed!(5)
parms = (utility_noise=true,
        u0 = 1.0, # initial utility
        u0Δ = .98, # utility decrement 
        τu = .6) # utility threshold
scheduler = ACTRScheduler(;model_trace=true)
task = PVT(;scheduler, n_trials=2, visible=true, realtime=true)
model = init_model(scheduler, task; parms...)
run!(model, task)