using ACTRSimulators, Test, ACTRModels, Random
import ACTRSimulators: start!, press_key!
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
actr = ACTR(;scheduler, visicon, procedural, visual_location, visual, motor, declarative)

function can_attend(actr)
    c1(actr) = !isempty(actr.visual_location.buffer)
    c2(actr) = !actr.visual.state.busy
    return c1, c2
end  

function can_encode(actr)
    c1(actr) = !isempty(actr.visual.buffer)
    c2(actr) = !actr.imaginal.state.busy
    return c1, c2
end    

function can_stop(actr)
    c1(actr) = !actr.imaginal.state.empty
    return (c1,)
end

function attend_action(actr, task)
    buffer = actr.visual_location.buffer
    chunk = deepcopy(buffer[1])
    clear_buffer!(actr.visual_location)
    attending!(actr, chunk)
    return nothing
end

function encode_action(actr, task)
    buffer = actr.visual.buffer
    chunk = deepcopy(buffer[1])
    clear_buffer!(actr.visual)
    encoding!(actr, chunk)
    return nothing
end

function stop(actr, task)
    stop!(actr.scheduler)
end

rule1 = Rule(;conditions=can_attend, action=attend_action, actr, task, name="Attend")
push!(procedural.rules, rule1)

rule2 = Rule(;conditions=can_encode, action=encode_action, actr, task, name="Encode")
push!(procedural.rules, rule2)

rule3 = Rule(;conditions=can_stop, action=stop, actr, task, name="Stop")
push!(procedural.rules, rule3)

run!(actr, task)
chunk = actr.imaginal.buffer[1]
@test chunk.slots == (color = :black, text = "hello", x = 300.0, y = 300.0)

observed = map(x->x.description, scheduler.complete_events)
expected = [
    "Starting", 
    "Present Stimulus", 
    "Selected Attend", 
    "Attend", 
    "Selected Encode",
    "Create New Chunk",
    "Selected Stop",
]
@test expected == observed