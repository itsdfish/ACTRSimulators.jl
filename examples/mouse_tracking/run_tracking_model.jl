###################################################################################################
#                                        Load Packages
###################################################################################################
cd(@__DIR__)
using Pkg
Pkg.activate("../..")
Pkg.activate("../")
using ACTRModels
using ACTRSimulators
using ConcreteStructs
using DiscreteEventsLite
using Distributions
using Gtk
using Random
using Revise

import ACTRSimulators: start!, repaint!
include("tracking_task.jl")
include("tracking_model.jl")
###################################################################################################
#                                        Run Model
###################################################################################################
scheduler = ACTRScheduler(; model_trace = true)
task = Tracking(; scheduler, visible = true, realtime = true)
procedural = Procedural()
T = vo_to_chunk() |> typeof
visual_location = VisualLocation(buffer = T[])
visual = Visual(buffer = T[])
visicon = VisualObject[]
motor = Motor()
actr = ACTR(; scheduler, procedural, visual_location, visual, motor, visicon)
rule1 = Rule(; conditions = can_attend, action = attend_action, actr, task, name = "Attend")
push!(procedural.rules, rule1)

rule2 = Rule(; conditions = can_find, action = find_action, actr, task, name = "Find")
push!(procedural.rules, rule2)

run!(actr, task, 30.0)
