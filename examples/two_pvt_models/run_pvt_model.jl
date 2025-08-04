###################################################################################################
#                                        Load Packages
###################################################################################################
cd(@__DIR__)
using Pkg
Pkg.activate("../")
using ACTRModels
using ACTRSimulators
using DiscreteEventsLite
using Distributions
using Gtk
using Random
using Revise
import ACTRSimulators: start!, press_key!, repaint!
include("../pvt_example/pvt.jl")
include("../pvt_example/pvt_model.jl")
###################################################################################################
#                                        Run Model
###################################################################################################
scheduler = ACTRScheduler(; model_trace = true)
task = PVT(; scheduler, n_trials = 4, visible = true, realtime = true)
n_models = 2
models = map(id -> init_model(scheduler, task, id), 1:n_models)
@time run!(models, task)
