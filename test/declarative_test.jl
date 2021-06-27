using ACTRSimulators, Test, ACTRModels, Random
Random.seed!(8985)
include("task.jl")

scheduler = ACTRScheduler(;model_trace=true, store=true)
task = SimpleTask(;scheduler)
procedural = Procedural()
T = vo_to_chunk() |> typeof
visual_location = VisualLocation(buffer=T[])
visual = Visual(buffer=T[])
visicon = VisualObject[]
motor = Motor()
memory = [Chunk(;animal=:dog), Chunk(;animal=:cat)]
declarative = Declarative(;memory)
actr = ACTR(;scheduler, procedural, visual_location, visual, motor, declarative, visicon)

function can_retrieve(actr)
    c1(actr) = !actr.declarative.state.busy
    return all_match(actr, (c1,))
end

function can_stop(actr)
    c1(actr) = !actr.declarative.state.empty
    return all_match(actr, (c1,))
end

function retrieve_chunk(actr, task)
    retrieving!(actr; animal=:dog)
end

function stop(actr, task)
    stop!(actr.scheduler)
end

rule1 = Rule(;conditions=can_retrieve, action=retrieve_chunk, actr, task, name="Retrieve")
push!(procedural.rules, rule1)

rule2 = Rule(;conditions=can_stop, action=stop, actr, task, name="Stop")
push!(procedural.rules, rule2)
run!(actr, task)
chunk = actr.declarative.buffer[1]
@test chunk.slots == (animal=:dog,)

observed = map(x->x.description, scheduler.complete_events)
expected = [
    "Starting", 
    "Selected Retrieve", 
    "Retrieve", 
    "Selected Stop"
]
@test expected == observed