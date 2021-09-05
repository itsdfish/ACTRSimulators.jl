using ACTRSimulators, Test, ACTRModels, Random
import ACTRSimulators: start!, press_key!
Random.seed!(8985)
include("task.jl")

function can_retrieve(actr)
    c1(actr) = !actr.declarative.state.busy
    return all_match(actr, c1)
end

function can_stop(actr)
    c1(actr) = !actr.declarative.state.empty
    return all_match(actr, c1)
end

function retrieve_chunk(actr, task)
    retrieving!(actr; animal=:dog)
end

function stop(actr, task)
    stop!(actr.scheduler)
end

models = ACTR[]

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
rule1 = Rule(;conditions=can_retrieve, action=retrieve_chunk, actr, task, name="Retrieve")
push!(procedural.rules, rule1)

rule2 = Rule(;conditions=can_stop, action=stop, actr, task, name="Stop")
push!(procedural.rules, rule2)
push!(models, actr)

procedural = Procedural()
T = vo_to_chunk() |> typeof
visual_location = VisualLocation(buffer=T[])
visual = Visual(buffer=T[])
visicon = VisualObject[]
motor = Motor()
memory = [Chunk(;animal=:dog), Chunk(;animal=:cat)]
declarative = Declarative(;memory)
actr = ACTR(;name="model2", scheduler, procedural, visual_location, visual, motor, declarative, visicon)
rule1 = Rule(;conditions=can_retrieve, action=retrieve_chunk, actr, task, name="Retrieve")
push!(procedural.rules, rule1)

rule2 = Rule(;conditions=can_stop, action=stop, actr, task, name="Stop")
push!(procedural.rules, rule2)
push!(models, actr)

run!(models, task)
chunk = models[1].declarative.buffer[1]
@test chunk.slots == (animal=:dog,)

chunk = models[2].declarative.buffer[1]
@test chunk.slots == (animal=:dog,)

complete_events = scheduler.complete_events
model1_events = filter(x->x.id == "model1", complete_events)
observed = map(x->x.description, model1_events)
expected = [
    "Starting", 
    "Selected Retrieve", 
    "Retrieve", 
    "Selected Stop"
]
@test expected == observed

complete_events = scheduler.complete_events
model2_events = filter(x->x.id == "model2", complete_events)
observed = map(x->x.description, model2_events)
expected = [
    "Starting", 
    "Selected Retrieve", 
    "Retrieve", 
]
@test expected == observed