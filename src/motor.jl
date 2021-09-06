"""
    responding!(actr, task, key, args...; kwargs...)

Sets the declarative motor module as busy and registers a new event for executing
a key stroke

# Arguments 

- `actr`: an ACT-R model object 
- `task`: a task that is a subtype of `AbstractTask`
- `key`: a string representing a response key
"""
function responding!(actr, task, key, args...; kwargs...)
    actr.motor.state.busy = true
    description = "Respond"
    type = "model"
    id = get_name(actr)
    tΔ = rnd_time(.060)
    register!(actr, respond!, after, tΔ , actr, task, key;
        id, description, type)
    return tΔ
end

"""
    respond!(actr, task, key, args...; kwargs...)

Executes a motor response with user defined `press_key!` function and sets module state to
busy = false.

# Arguments 

- `actr`: an ACT-R model object 
- `task`: a task that is a subtype of `AbstractTask`
- `key`: a string representing a response key
"""
function respond!(actr, task, key)
    actr.motor.state.busy = false
    press_key!(task, actr, key)
end