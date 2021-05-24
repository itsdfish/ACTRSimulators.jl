mutable struct SimpleTask{T,F1,F2} <: AbstractTask 
    scheduler::T
    visible::Bool
    realtime::Bool
    speed::Float64
    screen::Vector{VisualObject}
    press_key!::F1
    start!::F2
end

function SimpleTask(;
    scheduler, 
    visible=false, 
    realtime=false, 
    speed=1.0,
    screen=Vector{VisualObject}(),
    press_key! = press_key!,
    start! = start!
    )
    SimpleTask(scheduler, visible, realtime, speed, screen, press_key!, start!)
end

function start!(task::SimpleTask, model)
    isi = 2.0
    description = "Present Stimulus"
    register!(task.scheduler, present_stimulus, after, isi, task, model;
        description) 
end

function present_stimulus(task, model)
    vo = VisualObject(;text="hello")
    add_to_visicon!(model, vo; stuff=true)
    push!(task.screen, vo)
end

function press_key!(task, actr, key)
    empty!(task.screen)
end