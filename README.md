# ACTRSimulators

ACTRSimulators.jl is a package for developing discrete event simulations of the ACT-R cognitive architecture. Although the basic framework for conducting simulations has been developed, currently some 
features of ACT-R have not been implimented. 

# Example

As a simple example, we will develop an ACT-R model of the psychomotor vigilence task (PVT). The PVT is a reaction time task used to measure vigilance decrements stemming from fatigue. On each trial, a stimulus is presented after a random delay lasting 2 to 10 seconds. Once a response is made by keystroke, the next trial begins. Key components of the code will be described below. The full source code can be found in `Examples/PVT_Example`.


After installing `ACTRSimulators.jl`, the first step is to load the following dependencies.

```julia
using ACTRSimulators, Gtk, Cairo
include("PVT.jl")
include("PVT_Model.jl")
```

```julia
scheduler = Scheduler(;trace=true)
task = PVT(;scheduler, n_trials=2, visible=true, realtime=true)
procedural = Procedural()
T = vo_to_chunk() |> typeof
visual_location = VisualLocation(buffer=T[])
visual = Visual(buffer=T[])
motor = Motor()
actr = ACTR(;scheduler, procedural, visual_location, visual, motor)
```

# Production Rules

A production rule consists of two sets of higher order functions: one set for the conditions and another set for the actions. The PVT model uses three production rules: `wait` for the stimulus to appear, `attend` to the stimulus once it appears, `respond` to the stimulus after attending to it. 

## Conditions

The conditions for a production rule is a set of functions that return a `Bool` or a utility value proportional to the degree of match. By convention, the name for the conditions for a production rule is prefixed by "can". For example, `can_wait` returns a set of functions that evaluate the conditions for executing the `wait` production rule. Each condition requires an `actr` model object, `args...` and `kwargs...`. 

### Wait

The model will wait if the `visual_location` and `visual` buffers are empty and the same modules are not busy. 

```julia 

function can_wait()
    c1(actr, args...; kwargs...) = isempty(actr.visual_location.buffer)
    c2(actr, args...; kwargs...) = isempty(actr.visual.buffer)
    c3(actr, args...; kwargs...) = !actr.visual.state.busy
    c4(actr, args...; kwargs...) = !actr.motor.state.busy
    return (c1,c2,c3,c4)
end
```

### Attend

Upon stimulus presentation, a visual object is "stuffed" into the `visual_location` buffer. The `attend` production rule will execute if the `visual_location` buffer is not empty and the `visual` module is not busy. 

```julia 
function can_attend()
    c1(actr, args...; kwargs...) = !isempty(actr.visual_location.buffer)
    c2(actr, args...; kwargs...) = !actr.visual.state.busy
    return (c1,c2)
end
```
### Respond

Once the model attends to the stimulus, it can execute a response. The `respond` production rule will fire if the `visual` buffer is not empty and the `motor` module is not busy. 

```julia 
function can_respond()
    c1(actr, args...; kwargs...) = !isempty(actr.visual.buffer)
    c2(actr, args...; kwargs...) = !actr.motor.state.busy
    return (c1,c2)
end
```


## Actions

After a production rule is selected, a set of actions are executed that modify the architecture and possibly modify the exeternal environment. Each production rule is associated with an action function. For example, the action function for the production rule wait is `wait_action`. Each condition requires an `actr` model object, `args...` and `kwargs...`. A `task` object is passed to the `motor_action` function to allow the model to interact with the external world. 
### Wait 

The purpose of the `wait` production rule is to surpress the execution of other production rules when the stimulus has not appeared. There is not time cost associated with firing the `wait` production rule. Accordingly, an empty function `()->()` is immediately registered to the scheduler using the keyword `now`.

```julia 
function wait_action(actr, args...; kwargs...)
    description = "Wait"
    register!(actr.scheduler, ()->(), now; description)
    return nothing
end
```

### Attend

When the `attend` production rule is selected, the chunk in the `visual_location` buffer is copied and passed to the function `attending`, which adds the chunk after a time delay that represents the time to shift visual attention. In addition, the buffer for `visual_location` is immediately cleared.

```julia 
function attend_action(actr, task, args...; kwargs...)
    buffer = actr.visual_location.buffer
    chunk = deepcopy(buffer[1])
    clear_buffer!(actr.visual_location)
    attending!(actr, chunk)
    return nothing
end
```

### Respond 

```julia 
function respond_action(actr, task, args...; kwargs...)
    clear_buffer!(actr.visual)
    key = "sb"
    responding!(actr, task, key)
    return nothing
end
```

```julia 
conditions = can_attend()
rule1 = Rule(;conditions, action=attend_action, actr, task, name="Attend")
push!(procedural.rules, rule1)
conditions = can_wait()
rule2 = Rule(;conditions, action=wait_action, actr, task, name="Wait")
push!(procedural.rules, rule2)
conditions = can_respond()
rule3 = Rule(;conditions, action=respond_action, actr, task, name="Respond")
push!(procedural.rules, rule3)
```

