import ACTRSimulators: start!
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

function can_stop()
    c1(actr, args...; kwargs...) = !actr.visual_location.state.empty
    return (c1,)
end

function stop(actr, task, args...; kwargs...)
    stop!(actr.scheduler)
end

conditions = can_stop()
rule1 = Rule(;conditions, action=stop, actr, task, name="Stop")
push!(procedural.rules, rule1)
run!(actr, task)
chunk = actr.visual_location.buffer[1]
@test chunk.slots == (color=:black,text="hello")