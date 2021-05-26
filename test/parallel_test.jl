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

function can_attend(actr)
    c1(actr) = !isempty(actr.visual_location.buffer)
    c2(actr) = !actr.visual.state.busy
    return all_match(actr, (c1,c2))
end     

function can_respond(actr)
    c1(actr) = !isempty(actr.visual.buffer)
    c2(actr) = !actr.motor.state.busy
    c3(actr) = !actr.imaginal.state.busy
    return all_match(actr, (c1,c2,c3))
end   

function attend_action(actr, task)
    buffer = actr.visual_location.buffer
    chunk = deepcopy(buffer[1])
    clear_buffer!(actr.visual_location)
    attending!(actr, chunk)
    return nothing
end

function motor_action(actr, task)
    buffer = actr.visual.buffer
    chunk = deepcopy(buffer[1])
    clear_buffer!(actr.visual)
    encoding!(actr, chunk)

    key = chunk.slots.text
    responding!(actr, task, key)
    return nothing
end

rule1 = Rule(;conditions=can_attend, action=attend_action, actr, task, name="Attend")
push!(procedural.rules, rule1)

rule2 = Rule(;conditions=can_respond, action=motor_action, actr, task, name="Respond")
push!(procedural.rules, rule2)

run!(actr, task)

@test isempty(task.screen)
@test !isempty(actr.imaginal.buffer)

observed = map(x->x.description, scheduler.complete_events)
expected = [
    "Starting", 
    "Present Stimulus", 
    "Selected Attend", 
    "Attend", 
    "Selected Respond",
    "Respond",
    "Create New Chunk"
]
@test expected == observed