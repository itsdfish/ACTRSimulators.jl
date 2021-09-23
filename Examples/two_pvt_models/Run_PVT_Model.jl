###################################################################################################
#                                        Load Packages
###################################################################################################
cd(@__DIR__)
using Pkg
Pkg.activate("../..")
using Revise, ACTRSimulators
import_gui()
import ACTRSimulators: start!, press_key!, repaint!
include("../PVT_Example/PVT.jl")
include("../PVT_Example/PVT_Model.jl")
###################################################################################################
#                                        Run Model
###################################################################################################
scheduler = ACTRScheduler(;model_trace=true)
task = PVT(;scheduler, n_trials=4, visible=true, realtime=true)
n_models = 2
models = map(id -> init_model(scheduler, task, id), 1:n_models)
@time run!(models, task)