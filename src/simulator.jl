"""
*AbstractTask*

An abstract type for a task. A task requires the following fields:

- `visible`: shows GUI if true
- `realtime`: executes model in realtime if true
- `speed`: speed of realtime model execution
- `press_key!`: a user-defined function for handling responses, which has the following signature: press_key!(task::Task, actr, key) where
    `Task` <: `AbstractTask`
- `start!`: a user-defined function for starting the simulation in `run!`. The function signature is start!(task::Task, actr), where `Task` <: `AbstractTask`
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
    press_key!::F1
    start!::F2
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
    press_key=press_key!,
    start! =start!
    )
    visible ? ((canvas,window) = setup_window(width)) : nothing
    visible ? Gtk.showall(window) : nothing
    return PVT(n_trials, trial, lb, ub, width, height, scheduler, screen, canvas, window, visible,
        realtime, speed, press_key!, start!)
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
- `events`: a priority queue of events
- `time`: current time of the system 
- `running`: simulation can run if true
- `model_trace`: will print out model events if true
- `task_trace`: will print out task events if true
- `store`: will store a vector of completed events if true
- `complete_events`: an optional vector of completed events
"""
mutable struct ACTRScheduler{PQ<:PriorityQueue,E} <: AbstractScheduler
    events::PQ
    time::Float64
    running::Bool
    model_trace::Bool
    task_trace::Bool
    store::Bool
    complete_events::E
end

"""
Constructor for Scheduler with default keyword values:

```julia 
ACTRScheduler(;event=Event, time=0.0, running=true, model_trace=false, task_trace=false, store=false)
```
"""
function ACTRScheduler(;event=Event, time=0.0, running=true, model_trace=false, task_trace=false, store=false)
    events = PriorityQueue{event,Float64}()
    return ACTRScheduler(events, time, running, model_trace, task_trace, store, Vector{event}())
end

"""
    run!(actr, task::AbstractTask, until=Inf)

Simulate an ACT-R model

- `actr`: an ACT-R model object 
- `task`: a task that is a subtype of `AbstractTask`
- `until`: a specified termination time unless terminated sooner manually. Default is Inf
"""
function run!(actr, task::AbstractTask, until=Inf)
    s = task.scheduler
    last_event!(s, until)
    task.start!(task, actr)
    start!(actr)
    fire!(actr)
    while is_running(s, until)
        next_event!(s, actr, task)
    end
    s.task_trace && !s.running ? print_event(s.time, "", "Stopped") : nothing
    return nothing
end

next_event!(actr, task) = next_event!(actr.scheduler, actr, task)

"""
    next_event!(s, actr, task)

Dequeue and process a single event. 

- `s`: an event scheduler
- `actr`: an ACT-R model object 
- `task`: a task that is a subtype of `AbstractTask`
"""
function next_event!(s, actr, task)
    event = dequeue!(s.events)
    pause(task, event)
    s.time = event.time
    event.fun()
    fire!(actr)
    s.store ? push!(s.complete_events, event) : nothing
    s.model_trace && event.type == "model" ? print_event(event) : nothing
    s.task_trace && event.type !== "model" ? print_event(event) : nothing
    return nothing 
end

"""
    pause(task, event)

Pauses simulation for specified `speed` if `realtime` in `task` is true.

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

- `task`: a task that is a subtype of `AbstractTask`
- `actr`: an ACT-R model object 
"""
function start!(actr)
    register!(actr, ()->(), now; description="Starting")
end

"""
    fire!(actr)

Selects a production rule and registers conflict resolution and new events for selected production rule

- `actr`: an ACT-R model object 
"""
function fire!(actr)
    actr.procedural.state.busy ? (return nothing) : nothing
    rules = actr.parms.select_rule(actr)
    isempty(rules) ? (return nothing) : nothing
    rule = rules[1]
    description = "Selected "*rule.name
    type = "model"
    tΔ = rnd_time(.05)
    resolving(actr, true)
    f(r, a, v) = (resolving(a, v), r.action()) 
    register!(actr, f, after, tΔ, rule, actr, false; description, type)
    return nothing 
end

resolving(actr, v) = actr.procedural.state.busy = v

function register!(actr::AbstractACTR, fun, when::Now, args...; id="", type="", description="", kwargs...)
    scheduler = actr.scheduler
    register!(scheduler, fun, scheduler.time, args...; id, type, description, kwargs...)
end

function register!(actr::AbstractACTR, fun, when::At, t, args...; id="", type="", description="", kwargs...)
    scheduler = actr.scheduler
    register!(scheduler, fun, t, args...; id, type, description, kwargs...)
end

function register!(actr::AbstractACTR, fun, when::After, t, args...; id="", type="", description="", kwargs...)
    scheduler = actr.scheduler
    register!(scheduler, fun, scheduler.time + t, args...; id, type, description, kwargs...)
end

function register!(actr::AbstractACTR, fun, when::Every, t, args...; id="", type="", description="", kwargs...)
    scheduler = actr.scheduler
    function f(args...; kwargs...) 
        fun1 = ()->fun(args...; kwargs...)
        fun1()
        register!(scheduler, fun, every, t, args...; id, type, description, kwargs...)
    end
    register!(scheduler, f, after, t, args...; id, type, description, kwargs...)
end

function register!(task::AbstractTask, fun, when::Now, args...; id="", type="", description="", kwargs...)
    scheduler = task.scheduler
    register!(scheduler, fun, scheduler.time, args...; id, type, description, kwargs...)
end

function register!(task::AbstractTask, fun, when::At, t, args...; id="", type="", description="", kwargs...)
    scheduler = task.scheduler
    register!(scheduler, fun, t, args...; id, type, description, kwargs...)
end

function register!(task::AbstractTask, fun, when::After, t, args...; id="", type="", description="", kwargs...)
    scheduler = task.scheduler
    register!(scheduler, fun, scheduler.time + t, args...; id, type, description, kwargs...)
end

function register!(task::AbstractTask, fun, when::Every, t, args...; id="", type="", description="", kwargs...)
    scheduler = task.scheduler
    function f(args...; kwargs...) 
        fun1 = ()->fun(args...; kwargs...)
        fun1()
        register!(scheduler, fun, every, t, args...; id, type, description, kwargs...)
    end
    register!(scheduler, f, after, t, args...; id, type, description, kwargs...)
end

function compute_utility!(actr)
    #@unpack σu, δu = actr.parms
    δu = 1.0
    σu = .5
    for r in get_rules(actr)
        c = count_mismatches(r)
        u = rand(Normal(c * δu, σu))
        r.utility = u
    end
end
  
function count_mismatches(rule)
    return count(c->!c(), rule.conditions)
end

"""
    attending!(actr, chunk, args...; kwargs...)

Sets visual module as busy and registers a new event to attend to a `chunk`
created by a visual object

- `actr`: an ACT-R model object 
- `chunk`: a memory chunk
- `x`: x coordinate of visual object. Default 0.
- `y`: y coordinate of visual object. Default 0. 
"""
function attending!(actr, chunk, x=0.0, y=0.0)
    actr.visual.state.busy = true
    description = "Attend"
    type = "model"
    tΔ = rnd_time(.085)
    register!(actr, attend!, after, tΔ , actr, chunk, x, y; description, type)
end

"""
    attend!(actr, chunk, args...; kwargs...)

Completes an attention shift by adding a `chunk` to the visual buffer and setting
states to busy = false and empty = false.

- `actr`: an ACT-R model object 
- `chunk`: a memory chunk 
"""
function attend!(actr, chunk, x, y)
    actr.visual.focus = [x,y]
    actr.visual.state.busy = false
    actr.visual.state.empty = false
    add_to_buffer!(actr.visual, chunk)
    return nothing 
end

"""
    encoding!(actr, chunk, args...; kwargs...)

Sets imaginal module as busy and registers a new event to create a new `chunk`

- `actr`: an ACT-R model object 
- `chunk`: a memory chunk 
"""
function encoding!(actr, chunk)
    actr.imaginal.state.busy = true
    description = "Create New Chunk"
    type = "model"
    tΔ = rnd_time(.200)
    register!(actr, encode!, after, tΔ , actr, chunk; description, type)
    return tΔ
end

"""
    encode!(actr, chunk, args...; kwargs...)

Completes the creation of a chunk and adds resulting `chunk` to the imaginal buffer. The buffer
states are set to busy = false and empty = false.

- `actr`: an ACT-R model object 
- `chunk`: a memory chunk 
"""
function encode!(actr, chunk)
    actr.imaginal.state.busy = false
    actr.imaginal.state.empty = false
    add_to_buffer!(actr.imaginal, chunk)
    return nothing 
end

"""
    retrieving!(actr, chunk, args...; kwargs...)

Sets the declarative memory module as busy and Submits a request for a chunk and registers 
a new event for the retrieval

- `actr`: an ACT-R model object 
- `request...`: a variable list of slot-value pairs
"""
function retrieving!(actr; request...)
    actr.declarative.state.busy = true
    description = "Retrieve"
    type = "model"
    cur_time = get_time(actr)
    chunk = retrieve(actr, cur_time; request...)
    tΔ = compute_RT(actr, chunk)
    register!(actr, retrieve!, after, tΔ , actr, chunk; description, type)
    return tΔ
end

"""
    retrieve!(actr, chunk, args...; kwargs...)

Completes a memory retrieval by adding chunk to declarative memory buffer and setting
busy = false and empty = false. Error is set to true if retrieval failure occurs.

- `actr`: an ACT-R model object 
- `request...`: a variable list of slot-value pairs
"""
function retrieve!(actr, chunk)
    actr.declarative.state.busy = false
    if isempty(chunk)
        actr.declarative.state.error = true
    else
        actr.declarative.state.empty = false
        add_to_buffer!(actr.declarative, chunk[1])
    end
    return nothing 
end

"""
    responding!(actr, task, key, args...; kwargs...)

Sets the declarative motor module as busy and registers a new event for executing
a key stroke

- `actr`: an ACT-R model object 
- `task`: a task that is a subtype of `AbstractTask`
- `key`: a string representing a response key
"""
function responding!(actr, task, key, args...; kwargs...)
    actr.motor.state.busy = true
    description = "Respond"
    type = "model"
    tΔ = rnd_time(.060)
    register!(actr, respond!, after, tΔ , actr, task, key;
        description, type)
    return tΔ
end

"""
    respond!(actr, task, key, args...; kwargs...)

Executes a motor response with user defined `press_key!` function and sets module state to
busy = false. 

- `actr`: an ACT-R model object 
- `task`: a task that is a subtype of `AbstractTask`
- `key`: a string representing a response key
"""
function respond!(actr, task, key)
    actr.motor.state.busy = false
    task.press_key!(task, actr, key)
end

function clear_buffer!(actr, imaginal::Imaginal)
    slots = imaginal.buffer[1].slots
    time = get_time(actr)
    add_chunk!(actr, time; slots...)
    clear_buffer!(imaginal)
    return nothing
end

"""
    clear_buffer!(mod::Mod)

Removes chunk from buffer and sets buffer state to

- `empty`: true 
- `busy`: false
- `error`: false
"""
function clear_buffer!(mod::Mod)
    mod.state.empty = true
    mod.state.busy = false
    mod.state.error = false
    empty!(mod.buffer)
    return nothing
end

remove_chunk!(mod::Mod) = empty!(mod.buffer)

"""
    add_to_buffer!(mod::Mod, chunk)

Add chunk to buffer. 

- `mod`: a module
- `chunk`: a memory chunk 
"""
function add_to_buffer!(mod::Mod, chunk)
    remove_chunk!(mod)
    push!(mod.buffer, chunk)
end

"""
    add_to_visicon!(actr, vo; stuff=false)

Adds a visual object to the visicon. If `stuff` is set to true, the visual object
is added to the visual location buffer. 

- `actr`: an ACT-R model object
- `vo`: visual object 
- `stuff`: buffer stuffing if true 
"""
function add_to_visicon!(actr, vo; stuff=false) 
    push!(actr.visual_location.visicon, deepcopy(vo))
    if stuff 
       chunk = vo_to_chunk(actr, vo)
       add_to_buffer!(actr.visual_location, chunk)
    end
    return nothing 
end

"""
    clear_visicon!(actr)

Clear all visual objects in visicon
"""
function clear_visicon!(visicon)
    empty!(visicon)
end

clear_visicon!(actr::AbstractACTR) = clear_visicon!(actr.visual_location.visicon)

"""
    remove_visual_object!(actr::AbstractACTR, vo)

Removes object from visicon. 

- `actr`: an ACT-R model object 
- `vo`: a visual object 
"""
remove_visual_object!(actr::AbstractACTR, vo) = remove_visual_object!(actr.visual_location.visicon, vo)

"""
    remove_visual_object!(visicon, vo)

Removes object from visicon. 

- `visicon`: a vector of visual objects
- `vo`: a visual object 
"""
function remove_visual_object!(visicon, vo)
    filter!(x->x != vo, visicon)
end

"""
    vo_to_chunk(vo=VisualObject())

Converts visible object to a chunk with color and text slots.
"""
vo_to_chunk(vo=VisualObject()) = Chunk(;color=vo.color, text=vo.text)

"""
    vo_to_chunk(actr, vo)

Converts visible object to a chunk with color and text slots, and sets time created to current time.

- `actr`: an ACT-R model object
- `vo`: visual object
"""
function vo_to_chunk(actr, vo)
    time_created = get_time(actr)
    return Chunk(;time_created, color=vo.color, text=vo.text)
end

"""
    all_match(actr, conditions) 

Checks whether all conditions of a production rule are satisfied. 

- `actr`: an ACT-R model object
- `conditions`: a collection of functions representing production rule conditions.
"""
function all_match(actr, conditions)
    for c in conditions
        !c(actr) ? (return false) : nothing
    end
    return true 
end

function import_gui()
    path = pathof(ACTRSimulators) |> dirname |> x->joinpath(x, "")
    include(path * "GUI.jl")
end