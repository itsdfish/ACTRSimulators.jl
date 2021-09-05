"""
** PVT **

- `n_trials`: number of trials
- `trial`: current trial
- `lb`: ISI lower bound
- `ub`: ISI upper bound
- `width`: screen width
- `height`: screen height
- `scheduler`: event scheduler
- `screen`: visual objects on screen
- `canvas`: GTK canvas
- `window`: GTK window
- `visible`: GUI visible
- `speed`: real time speed

Function Signature 

````julia
PVT(;n_trials=10, trial=1, lb=2.0, ub=10.0, width=600.0, height=600.0, scheduler=nothing, 
    screen=Vector{VisualObject}(), window=nothing, canvas=nothing, visible=false, speed=1.0)
````
"""
mutable struct PVT{T,W,C} <: AbstractTask 
    n_trials::Int
    trial::Int 
    lb::Float64
    ub::Float64 
    width::Float64
    hight::Float64
    scheduler::T
    screen::Vector{VisualObject}
    canvas::C
    window::W
    visible::Bool
    realtime::Bool
    speed::Float64
end

function PVT(;
    n_trials=10, 
    trial=1, 
    lb=2.0, 
    ub=10.0, 
    width=600.0, 
    height=600.0, 
    scheduler=nothing, 
    screen=Vector{VisualObject}(), 
    window=nothing, 
    canvas=nothing, 
    visible=false, 
    realtime=false,
    speed=1.0,
    )
    visible ? ((canvas,window) = setup_window(width)) : nothing
    visible ? Gtk.showall(window) : nothing
    return PVT(n_trials, trial, lb, ub, width, height, scheduler, screen, canvas, window, visible,
        realtime, speed)
end

function start!(task::PVT, actr)
    run_trial!(task, actr)
end

function sample_isi(task)
    return rand(Uniform(task.lb, task.ub))
end

function present_stimulus(task, actr)
    vo = VisualObject()
    add_to_visicon!(actr, vo; stuff=true)
    push!(task.screen, vo)
    w = task.width / 2
    task.visible ? draw_object!(task, "X", w, w) : nothing
end

function run_trial!(task, actr)
    isi = sample_isi(task)
    description = "present stimulus"
    register!(task, present_stimulus, after, isi, task, actr;
        description)
end

function press_key!(task::PVT, actr, key)
    if key == "sb"
        empty!(task.screen)
        task.visible ? clear!(task) : nothing
        if task.trial < task.n_trials
            task.trial += 1
            run_trial!(task, actr)
        else
            stop!(task.scheduler)
        end
    end
    return nothing
end

function repaint!(task::PVT, actr)
    #clear!(task)
    #draw_attention!(task, actr) 
end