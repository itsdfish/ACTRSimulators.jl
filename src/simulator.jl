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
    s.trace && !s.running ? print_event(s.time, "", "stopped") : nothing
    return nothing
end

next_event!(actr, task) = next_event!(actr.scheduler, actr, task)

function next_event!(s, actr, task)
    event = dequeue!(s.events)
    pause(task, event)
    s.time = event.time
    event.fun()
    fire!(actr)
    s.store ? push!(s.complete_events, event) : nothing
    s.trace ? print_event(event) : nothing
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
    if !isempty(rules)
        rule = rules[1]
        description = "Selected "*rule.name
        tΔ = rnd_time(.05)
        resolving(actr, true)
        f(r, a, v) = (resolving(a, v), r.action()) 
        register!(actr, f, after, tΔ, rule, actr, false; description)
    end
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

"""
function attending!(actr, chunk, args...; kwargs...)
    actr.visual.state.busy = true
    description = "Attend"
    tΔ = rnd_time(.085)
    register!(actr, attend!, after, tΔ , actr, chunk; description)
end

"""
    attend!(actr, chunk, args...; kwargs...)

Completes an attention shift by adding a `chunk` to the visual buffer and setting
states to busy = false and empty = false.

- `actr`: an ACT-R model object 
- `chunk`: a memory chunk 

"""
function attend!(actr, chunk, args...; kwargs...)
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
function encoding!(actr, chunk, args...; kwargs...)
    actr.imaginal.state.busy = true
    description = "Create New Chunk"
    tΔ = rnd_time(.200)
    register!(actr, encode!, after, tΔ , actr, chunk; description)
end

"""
    encode!(actr, chunk, args...; kwargs...)

Completes the creation of a chunk and adds resulting `chunk` to the imaginal buffer. The buffer
states are set to busy = false and empty = false.

- `actr`: an ACT-R model object 
- `chunk`: a memory chunk 

"""
function encode!(actr, chunk, args...; kwargs...)
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
function retrieving!(actr, args...; request...)
    actr.declarative.state.busy = true
    description = "Retrieve"
    cur_time = get_time(actr)
    chunk = retrieve(actr, cur_time; request...)
    tΔ = compute_RT(actr, chunk)
    register!(actr, retrieve!, after, tΔ , actr, chunk; description)
end

"""
    retrieve!(actr, chunk, args...; kwargs...)

Completes a memory retrieval by adding chunk to declarative memory buffer and setting
busy = false and empty = false. Error is set to true if retrieval failure occurs.

- `actr`: an ACT-R model object 
- `request...`: a variable list of slot-value pairs
"""
function retrieve!(actr, chunk, args...; kwargs...)
    actr.declarative.state.busy = false
    actr.declarative.state.empty = false
    if isempty(chunk)
        actr.declarative.state.error = true
    else
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
    tΔ = rnd_time(.060)
    register!(actr, respond!, after, tΔ , actr, task, key;
        description)
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

function clear_buffer!(mod::Mod)
    mod.state.empty = true
    mod.state.busy = false
    mod.state.error = false
    empty!(mod.buffer)
end

remove_chunk!(mod::Mod) = empty!(mod.buffer)

function add_to_buffer!(mod::Mod, chunk)
    remove_chunk!(mod)
    push!(mod.buffer, chunk)
end

function add_to_visicon!(actr, vo; stuff=false) 
    push!(actr.visual_location.visicon, deepcopy(vo))
    if stuff 
       chunk = vo_to_chunk(actr, vo)
       add_to_buffer!(actr.visual_location, chunk)
    end
    return nothing 
end

vo_to_chunk(vo=VisualObject()) = Chunk(;color=vo.color, text=vo.text)

function vo_to_chunk(actr, vo)
    time_created = get_time(actr)
    return Chunk(;time_created, color=vo.color, text=vo.text)
end
