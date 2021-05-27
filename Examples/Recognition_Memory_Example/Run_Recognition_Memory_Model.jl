###################################################################################################
#                                        Load Packages
###################################################################################################
cd(@__DIR__)
using Pkg
Pkg.activate("../..")
using Revise, ConcreteStructs, ACTRSimulators, Gtk, Cairo
include("Recognition_Memory_Task.jl")
include("Recognition_Memory_Model.jl")
###################################################################################################
#                                        Run Model
###################################################################################################
parms = (bll=true,noise=true, d=.5, s=.2,τ = 0.0)
scheduler = ACTRScheduler(;model_trace=true)
stimuli = populate_lists()
task = Task(;scheduler, visible=true, realtime=true, stimuli...)
procedural = Procedural()
imaginal = Imaginal()
T = Chunk(;word="") |> typeof
declarative = Declarative(;memory=T[])
goal = Goal(;buffer=Chunk(;goal=:study))
T = vo_to_chunk() |> typeof
visual_location = VisualLocation(buffer=T[])
visual = Visual(buffer=T[])
motor = Motor()
actr = ACTR(;scheduler, imaginal, procedural, goal, visual_location, 
    declarative, visual, motor, parms...)
rule1 = Rule(;conditions=can_attend, action=attend_action, actr, task, name="Attend")
push!(procedural.rules, rule1)
rule2 = Rule(;conditions=can_encode, action=encode_action, actr, task, name="Encode")
push!(procedural.rules, rule2)
rule3 = Rule(;conditions=can_respond, action=respond_action, actr, task, name="Respond")
push!(procedural.rules, rule3)
run!(actr, task)