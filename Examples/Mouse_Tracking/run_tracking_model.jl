###################################################################################################
#                                        Load Packages
###################################################################################################
cd(@__DIR__)
using Pkg
Pkg.activate("../..")
using Revise, ACTRSimulators, ConcreteStructs
import_gui()
include("tracking_task.jl")
include("tracking_model.jl")
###################################################################################################
#                                        Run Model
###################################################################################################
scheduler = ACTRScheduler(;model_trace=true)
task = Tracking(;scheduler, visible=true, realtime=true)
procedural = Procedural()
T = vo_to_chunk() |> typeof
visual_location = VisualLocation(buffer=T[])
visual = Visual(buffer=T[])
visicon = VisualObject[]
motor = Motor()
actr = ACTR(;scheduler, procedural, visual_location, visual, motor, visicon)
rule1 = Rule(;conditions=can_attend, action=attend_action, actr, task, name="Attend")
push!(procedural.rules, rule1)
rule3 = Rule(;conditions=can_respond, action=respond_action, actr, task, name="Respond")
push!(procedural.rules, rule3)
run!(actr, task, 30.0)