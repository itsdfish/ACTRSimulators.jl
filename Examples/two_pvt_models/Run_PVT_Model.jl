###################################################################################################
#                                        Load Packages
###################################################################################################
cd(@__DIR__)
using Pkg
Pkg.activate("../..")
using Revise, ACTRSimulators
import ACTRSimulators: start!, press_key!, repaint!
import_gui()
include("../PVT_Example/PVT.jl")
include("../PVT_Example/PVT_Model.jl")
###################################################################################################
#                                        Run Model
###################################################################################################
scheduler = ACTRScheduler(;model_trace=true)
task = PVT(;scheduler, n_trials=2, visible=true, realtime=true)
n_models = 2
models = map(id -> init_model(scheduler, task, id), 1:n_models)
run!(models, task)