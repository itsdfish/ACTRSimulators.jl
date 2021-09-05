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
scheduler = ACTRScheduler(;model_trace=false)
task = PVT(;scheduler, n_trials=1000, visible=false, realtime=false)
n_models = 10
models = map(id -> init_model(scheduler, task, id), 1:n_models)
@time run!(models, task)