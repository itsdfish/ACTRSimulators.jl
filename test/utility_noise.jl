using ACTRSimulators, Test, ACTRModels, DataFrames, Random
import ACTRSimulators: start!, press_key!
using Statistics

Random.seed!(8985)
include("task.jl")

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

function can_respond1(actr)
    c1(actr) = !isempty(actr.imaginal.buffer)
    c2(actr) = !actr.motor.state.busy
    return c1, c2
end

function can_respond2(actr)
    c1(actr) = !isempty(actr.imaginal.buffer)
    c2(actr) = !actr.motor.state.busy
    return c1, c2
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

function motor_action1(actr, task)
    buffer = actr.imaginal.buffer
    chunk = deepcopy(buffer[1])
    clear_buffer!(actr.imaginal)
    key = "j"
    responding!(actr, task, key)
    return nothing
end

function motor_action2(actr, task)
    buffer = actr.imaginal.buffer
    chunk = deepcopy(buffer[1])
    clear_buffer!(actr.imaginal)
    key = "f"
    responding!(actr, task, key)
    return nothing
end

parms = (
    utility_noise = true,
)

scheduler = ACTRScheduler(; model_trace = false)
task = SimpleTask(; scheduler)
procedural = Procedural()
T = vo_to_chunk() |> typeof
visual_location = VisualLocation(buffer = T[])
visual = Visual(buffer = T[])
visicon = VisualObject[]
motor = Motor()
memory = [Chunk(; animal = :dog), Chunk(; animal = :cat)]
declarative = Declarative(; memory)
actr = ACTR(;
    scheduler,
    procedural,
    visual_location,
    visual,
    motor,
    declarative,
    visicon,
    parms...
)

rule1 = Rule(; conditions = can_attend, action = attend_action, actr, task, name = "Attend")
push!(procedural.rules, rule1)

rule2 = Rule(; conditions = can_encode, action = encode_action, actr, task, name = "Encode")
push!(procedural.rules, rule2)

rule3 = Rule(;
    conditions = can_respond1,
    action = motor_action1,
    actr,
    task,
    name = "Respond j"
)
push!(procedural.rules, rule3)

rule4 = Rule(;
    conditions = can_respond2,
    action = motor_action2,
    actr,
    task,
    name = "Respond f"
)
push!(procedural.rules, rule4)

map(_ -> run!(actr, task), 1:1000)

p_j = mean(task.data.key .== "j")

@test p_j ≈ 0.5 atol = 0.01
