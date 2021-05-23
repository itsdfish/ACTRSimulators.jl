import ACTRSimulators: start!, press_key!
using ACTRSimulators, Test, ACTRModels, Random
Random.seed!(8985)

mutable struct SimpleTask{T} <: AbstractTask 
    scheduler::T
    visible::Bool
    realtime::Bool
    speed::Float64
    screen::Vector{VisualObject}
end

function SimpleTask(;scheduler, visible=false, realtime=false, speed=1.0,
    screen=Vector{VisualObject}())
    SimpleTask(scheduler, visible, realtime, speed, screen)
end

function start!(task::SimpleTask, model)
    isi = 2.0
    description = "present stimulus"
    register!(task.scheduler, present_stimulus, after, isi, task, model;
        description) 
end

function present_stimulus(task, model)
    vo = VisualObject(;text="hello")
    add_to_visicon!(model, vo; stuff=true)
    push!(task.screen, vo)
end

function press_key!(task::SimpleTask, actr, key)
    empty!(task.screen)
    stop!(task.scheduler)
end

scheduler = Scheduler(;trace=true)
task = SimpleTask(;scheduler)
procedural = Procedural()
T = vo_to_chunk() |> typeof
visual_location = VisualLocation(buffer=T[])
visual = Visual(buffer=T[])
motor = Motor()
memory = [Chunk(;animal=:dog), Chunk(;animal=:cat)]
declarative = Declarative(;memory)
actr = ACTR(;scheduler, procedural, visual_location, visual, motor, declarative)

function can_attend()
    c1(actr, args...; kwargs...) = !isempty(actr.visual_location.buffer)
    c2(actr, args...; kwargs...) = !actr.visual.state.busy
    return (c1,c2)
end  

function can_encode()
    c1(actr, args...; kwargs...) = !isempty(actr.visual.buffer)
    c2(actr, args...; kwargs...) = !actr.imaginal.state.busy
    return (c1,c2)
end    

function can_respond()
    c1(actr, args...; kwargs...) = !isempty(actr.imaginal.buffer)
    c2(actr, args...; kwargs...) = !actr.motor.state.busy
    return (c1,c2)
end   

function attend_action(actr, task, args...; kwargs...)
    buffer = actr.visual_location.buffer
    chunk = deepcopy(buffer[1])
    clear_buffer!(actr.visual_location)
    attending!(actr, chunk)
    return nothing
end

function encode_action(actr, task, args...; kwargs...)
    buffer = actr.visual.buffer
    chunk = deepcopy(buffer[1])
    clear_buffer!(actr.visual)
    encoding!(actr, chunk)
    return nothing
end

function motor_action(actr, task, args...; kwargs...)
    buffer = actr.imaginal.buffer
    chunk = deepcopy(buffer[1])
    clear_buffer!(actr.imaginal)
    key = chunk.slots.text
    responding!(actr, task, key)
    return nothing
end

conditions = can_attend()
rule1 = Rule(;conditions, action=attend_action, actr, task, name="Attend")
push!(procedural.rules, rule1)

conditions = can_encode()
rule2 = Rule(;conditions, action=encode_action, actr, task, name="Encode")
push!(procedural.rules, rule2)

conditions = can_respond()
rule3 = Rule(;conditions, action=motor_action, actr, task, name="Respond")
push!(procedural.rules, rule3)

run!(actr, task)

@test isempty(task.screen)
