import ACTRSimulators: start!
using ACTRSimulators, Test, ACTRModels, Random
Random.seed!(8985)
include("task.jl")

scheduler = Scheduler(;trace=true, store=true)
task = SimpleTask(;scheduler)
procedural = Procedural()
T = vo_to_chunk() |> typeof
visual_location = VisualLocation(buffer=T[])
visual = Visual(buffer=T[])
motor = Motor()
memory = [Chunk(;animal=:dog), Chunk(;animal=:cat)]
declarative = Declarative(;memory)
actr = ACTR(;scheduler, procedural, visual_location, visual, motor, declarative) 

function can_stop(actr)
    c1(actr) = !actr.visual_location.state.empty
    return all_match(actr, (c1,))
end

function stop(actr, task)
    stop!(actr.scheduler)
end

rule1 = Rule(;conditions=can_stop, action=stop, actr, task, name="Stop")
push!(procedural.rules, rule1)
run!(actr, task)
chunk = actr.visual_location.buffer[1]
@test chunk.slots == (color=:black,text="hello")

observed = map(x->x.description, scheduler.complete_events)
expected = [
    "Starting", 
    "Present Stimulus"
]
@test expected == observed