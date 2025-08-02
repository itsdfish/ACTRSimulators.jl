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
parms = (utility_noise = true,  # utility noise
    u0 = 1.0,               # initial utility
    u0Δ = 0.98,              # utility decrement 
    τu0 = 0.60,              # utlity threshold decrement
    τuΔ = 0.98)              # utility threshold
scheduler = ACTRScheduler(; model_trace = true)
task = PVT(; scheduler, n_trials = 2, visible = true, realtime = true)
model = init_model(scheduler, task; parms...)
run!(model, task)
