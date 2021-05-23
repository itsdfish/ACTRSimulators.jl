# ACTRSimulators

```julia
using ACTRModels, ACTRSimulators, Gtk, Cairo
import ACTRSimulators: start!, press_key!
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

## Conditions

### Wait
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
```julia 
function can_attend()
    c1(actr, args...; kwargs...) = !isempty(actr.visual_location.buffer)
    c2(actr, args...; kwargs...) = !actr.visual.state.busy
    return (c1,c2)
end
```
### Resond

```julia 
function can_respond()
    c1(actr, args...; kwargs...) = !isempty(actr.visual.buffer)
    c2(actr, args...; kwargs...) = !actr.motor.state.busy
    return (c1,c2)
end
```


## Conditions

### Wait 

```julia 
function wait_action(actr, args...; kwargs...)
    description = "Wait"
    register!(actr.scheduler, ()->(), now; description)
    return nothing
end
```

### Attend 

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