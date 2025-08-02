"""
*AbstractTask*

An abstract type for a task. A task requires the following fields:

- `visible`: shows GUI if true
- `realtime`: executes model in realtime if true
- `speed`: speed of realtime model execution
- `scheduler`: a reference to the event scheduler

A task may optionally contain the following fields:

- `screen`: a vector of visual objects on the screen 
- `canvas`: a GUI object component
- `window`: a window for the GUI

*Example*

The following is an example of the task object for the PVT.

```julia
mutable struct PVT{T,W,C,F1,F2} <: AbstractTask 
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
```
The constructor for `PVT` is 

```julia
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

function setup_window(width)
	canvas = @GtkCanvas()
    window = GtkWindow(canvas, "PVT", width, width)
    Gtk.visible(window, true)
    @guarded draw(canvas) do widget
        ctx = getgc(canvas)
        rectangle(ctx, 0.0, 0.0, width, width)
        set_source_rgb(ctx, .8, .8, .8)
        fill(ctx)
    end
	return canvas,window
end
```
"""
abstract type AbstractTask end

"""
    ACTRScheduler <: AbstractScheduler

An ACT-R event scheduler object. 

# Fields 

- `events`: a priority queue of events
- `time`: current time of the system 
- `running`: simulation can run if true
- `model_trace`: will print out model events if true
- `task_trace`: will print out task events if true
- `store`: will store a vector of completed events if true
- `complete_events`: an optional vector of completed events

"""
mutable struct ACTRScheduler{PQ <: PriorityQueue, E} <: AbstractScheduler
    events::PQ
    time::Float64
    running::Bool
    model_trace::Bool
    task_trace::Bool
    store::Bool
    complete_events::E
end

"""
    ACTRScheduler(;event=Event, time=0.0, running=true, model_trace=false, task_trace=false, store=false)

Constructor for Scheduler with default keyword values:

# Keywords 

- `event`: a function that is executed at the specified time
- `time`: the time at which the event will be execute
- `running`: whether the model is running 
- `model_trace`: prints model trace if true
- `task_trace`: prints task trace if true 
- `store`: stores the executed events for replay if set to true 
"""
function ACTRScheduler(;
    event = Event,
    time = 0.0,
    running = true,
    model_trace = false,
    task_trace = false,
    store = false
)
    events = PriorityQueue{event, Float64}()
    return ACTRScheduler(
        events,
        time,
        running,
        model_trace,
        task_trace,
        store,
        Vector{event}()
    )
end

run!(actr::AbstractACTR, task::AbstractTask, until = Inf) = run!([actr], task, until)

"""
    run!(actr, task::AbstractTask, until=Inf)

Simulate an ACT-R model

# Arguments 

- `models`: a dictionary of ACT-R model objects
- `task`: a task that is a subtype of `AbstractTask`
- `until=Inf`: a specified termination time unless terminated sooner manually
"""
function run!(models, task::AbstractTask, until = Inf)
    s = task.scheduler
    last_event!(s, until)
    start!(task, models)
    start!.(models)
    fire!.(models)
    while is_running(s, until)
        next_event!(s, models, task)
    end
    s.task_trace && !s.running ? print_event(s.time, "", "Stopped") : nothing
    return nothing
end

next_event!(actr, task) = next_event!(actr.scheduler, actr, task)

"""
    next_event!(s, actr, task)

Dequeue and process a single event. 

# Arguments 

- `s`: an event scheduler
- `actr`: an ACT-R model object 
- `task`: a task that is a subtype of `AbstractTask`
"""
function next_event!(s, models, task)
    event = dequeue!(s.events)
    pause(task, event)
    s.time = event.time
    event.fun()
    fire!.(models)
    s.store ? push!(s.complete_events, event) : nothing
    s.model_trace && event.type == "model" ? print_event(event) : nothing
    s.task_trace && event.type !== "model" ? print_event(event) : nothing
    return nothing
end

"""
    pause(task, event)

Pauses simulation for specified `speed` if `realtime` in `task` is true.

# Arguments 

- `task`: a task that is a subtype of `AbstractTask`
- `event`: a task event or an internal event of the model
"""
function pause(task, event)
    !task.realtime ? (return nothing) : nothing
    t = (event.time - task.scheduler.time) / task.speed
    sleep(t)
    return nothing
end

"""
    start!(actr)

A function that initializes the simulation for the model.

# Arguments 

- `task`: a task that is a subtype of `AbstractTask`
- `actr`: an ACT-R model object 
"""
function start!(actr::AbstractACTR)
    register!(actr, () -> (), now; description = "Starting", id = get_name(actr))
    return nothing
end
