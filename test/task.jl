mutable struct SimpleTask{T,T1} <: AbstractTask 
    scheduler::T
    visible::Bool
    realtime::Bool
    speed::Float64
    screen::Vector{VisualObject}
    data::T1
end

function SimpleTask(;
    scheduler, 
    visible=false, 
    realtime=false, 
    speed=1.0,
    screen=Vector{VisualObject}(),
    )
    SimpleTask(scheduler, visible, realtime, speed, screen, DataFrame())
end

function start!(task::SimpleTask, model)
    isi = 2.0
    description = "Present Stimulus"
    register!(task, present_stimulus, after, isi, task, model;
        description) 
end

function present_stimulus(task, model)
    vo = VisualObject(;text="hello")
    add_to_visicon!(model, vo; stuff=true)
    push!(task.screen, vo)
end

function press_key!(task::SimpleTask, actr, key)
    empty!(task.screen)
    push!(task.data, (key=key,))
end