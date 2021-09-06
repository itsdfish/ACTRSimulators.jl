###################################################################################################
#                                        Load Packages
###################################################################################################
cd(@__DIR__)
using Pkg
Pkg.activate("../..")
using Revise, ACTRSimulators
import ACTRSimulators: start!, press_key!, repaint!
import_gui()
include("PVT.jl")
include("PVT_Model.jl")
###################################################################################################
#                                        Run Model
###################################################################################################
scheduler = ACTRScheduler(;model_trace=true)
task = PVT(;scheduler, n_trials=2, visible=true, realtime=true)
model = init_model(scheduler, task)
run!(model, task)