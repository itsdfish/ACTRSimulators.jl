###################################################################################################
#                                        Load Packages
###################################################################################################
cd(@__DIR__)
using Pkg
Pkg.activate("../..")
using Revise, ConcreteStructs, ACTRSimulators, DataFrames, FreqTables
import_gui()
include("Recognition_Memory_Task.jl")
include("Recognition_Memory_Model.jl")
###################################################################################################
#                                        Run Model
###################################################################################################
parms = (bll=true,noise=true, d=.5, s=.2,τ = 0.0, blc=1.0)
scheduler = ACTRScheduler(;model_trace=true)
stimuli = populate_lists()
data = DataFrame(word=String[], type=String[], response=String[])
task = Task(;scheduler, visible=true, realtime=true, n_blocks=2, data, stimuli...)
procedural = Procedural()
T = Chunk(;word="") |> typeof
imaginal = Imaginal(;buffer=T[])
declarative = Declarative(;memory=T[])
goal = Goal(;buffer=Chunk(;goal=:study))
T = vo_to_chunk() |> typeof
visual_location = VisualLocation(buffer=T[])
visual = Visual(buffer=T[])
visicon = VisualObject[]
motor = Motor()
actr = ACTR(;scheduler, imaginal, procedural, goal, visual_location, 
    declarative, visual, motor, visicon, parms...)
rule1 = Rule(;conditions=can_attend, action=attend_action, actr, task, name="Attend")
push!(procedural.rules, rule1)
rule2 = Rule(;conditions=can_encode, action=encode_action, actr, task, name="Encode")
push!(procedural.rules, rule2)
rule3 = Rule(;conditions=can_start, action=start_action, actr, task, name="Start Test")
push!(procedural.rules, rule3)
rule4 = Rule(;conditions=can_retrieve, action=retrieve_word, actr, task, name="Retrieve")
push!(procedural.rules, rule4)
rule5 = Rule(;conditions=can_respond_yes, action=respond_yes, actr, task, name="Respond Yes")
push!(procedural.rules, rule5)
rule6 = Rule(;conditions=can_respond_no, action=respond_no, actr, task, name="Respond No")
push!(procedural.rules, rule6);
run!(actr, task)
###################################################################################################
#                                        Analyze Responses
###################################################################################################
table = freqtable(task.data, :type, :response) |> prop
table /= .5