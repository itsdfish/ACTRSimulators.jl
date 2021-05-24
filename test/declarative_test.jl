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

function can_retrieve()
    c1(actr, args...; kwargs...) = !actr.declarative.state.busy
    return (c1,)
end

function can_stop()
    c1(actr, args...; kwargs...) = !actr.declarative.state.empty
    return (c1,)
end

function retrieve_chunk(actr, task, args...; kwargs...)
    retrieving!(actr; animal=:dog)
end

function stop(actr, task, args...; kwargs...)
    stop!(actr.scheduler)
end

conditions = can_retrieve()
rule1 = Rule(;conditions, action=retrieve_chunk, actr, task, name="Retrieve")
push!(procedural.rules, rule1)

conditions = can_stop()
rule2 = Rule(;conditions, action=stop, actr, task, name="Stop")
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