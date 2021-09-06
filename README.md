# ACTRSimulators

ACTRSimulators.jl is a package for developing discrete event simulations of the ACT-R cognitive architecture. Although the basic framework for conducting simulations has been developed, currently some 
features of ACT-R have not been implimented. 

# Example

As a simple example, we will develop an ACT-R model of the psychomotor vigilence task (PVT). The PVT is a reaction time task used to measure vigilance decrements stemming from fatigue. On each trial, a stimulus is presented after a random delay lasting 2 to 10 seconds. Once a response is made by keystroke, the next trial begins. Key components of the code will be described below. The full source code can be found in `Examples/PVT_Example`.


After installing `ACTRSimulators.jl`, the first step is to load the following dependencies.

```julia
using ACTRSimulators
import ACTRSimulators: start!, press_key!, repaint!
include("PVT.jl")
include("PVT_Model.jl")
import_gui()
```

Next, create an event scheduler as follows. When the option `model_trace` is set to true, a description and execution time will print for each processed model event. Task events can be added to the trace with `task_trace`. 

```julia 
scheduler = ACTRScheduler(;model_trace=true)
```

A task object is created with the `PVT` constructor, which includes options for the number of trials, whether the GUI is visible and whether the task executes in real time. 

```julia
task = PVT(;scheduler, n_trials=2, visible=true, realtime=true)
```

Now we will initialize the model. The model consists of components for the following modules:

- `procedural` memory
- `visual_location` 
- `visual`

Each of the modules are passed to the `actr` model object along with a reference to the scheduler. 

```julia
procedural = Procedural()
T = vo_to_chunk() |> typeof
visual_location = VisualLocation(buffer=T[])
visual = Visual(buffer=T[])
motor = Motor()
actr = ACTR(;scheduler, procedural, visual_location, visual, motor)
```

# Production Rules

A production rule consists of higher order functions: one for the conditions and another for the actions. The PVT model uses three production rules: `wait` for the stimulus to appear, `attend` to the stimulus once it appears, `respond` to the stimulus after attending to it. 

## Conditions

The conditions for a production rule is a set of functions that return a `Bool` or a utility value proportional to the degree of match. By convention, the name for the conditions for a production rule is prefixed by "can". For example, `can_wait` returns a set of functions that evaluate the conditions for executing the `wait` production rule. Each condition requires an `actr` model object. 

### Wait

The model will wait if the `visual_location` and `visual` buffers are empty and the same modules are not busy. 

```julia 
function can_wait(actr)
    c1(actr) = isempty(actr.visual_location.buffer)
    c2(actr) = isempty(actr.visual.buffer)
    c3(actr) = !actr.visual.state.busy
    c4(actr) = !actr.motor.state.busy
    return c1, c2, c3, c4
end
```

### Attend

Upon stimulus presentation, a visual object is "stuffed" into the `visual_location` buffer. The `attend` production rule will execute if the `visual_location` buffer is not empty and the `visual` module is not busy. 

```julia 
function can_attend(actr)
    c1(actr) = !isempty(actr.visual_location.buffer)
    c2(actr) = !actr.visual.state.busy
    return c1, c2
end
```
### Respond

Once the model attends to the stimulus, it can execute a response. The `respond` production rule will fire if the `visual` buffer is not empty and the `motor` module is not busy. 

```julia 
function can_respond(actr)
    c1(actr) = !isempty(actr.visual.buffer)
    c2(actr) = !actr.motor.state.busy
    return c1, c2
end
```

## Actions

After a production rule is selected, a set of actions are executed that modify the architecture and possibly modify the exeternal environment. Each production rule is associated with an action function. For example, the action function for the production rule wait is `wait_action`. Each action requires an `actr` model object and a `task` object or `args...` if the `task` is note used.
### Wait 

The purpose of the `wait` production rule is to surpress the execution of other production rules when the stimulus has not appeared. There is not time cost associated with firing the `wait` production rule. Accordingly, an empty function `()->()` is immediately registered to the scheduler using the keyword `now`.

```julia 
function wait_action(actr, args...)
    description = "Wait"
    register!(actr.scheduler, ()->(), now; description)
    return nothing
end
```

### Attend

When the `attend` production rule is selected, the chunk in the `visual_location` buffer is copied and passed to the function `attending`, which adds the chunk after a time delay that represents the time to shift visual attention. In addition, the buffer for `visual_location` is immediately cleared.

```julia 
function attend_action(actr, args...)
    buffer = actr.visual_location.buffer
    chunk = deepcopy(buffer[1])
    clear_buffer!(actr.visual_location)
    attending!(actr, chunk)
    return nothing
end
```

### Respond 
The function `respond_action` is executed upon selection of the `respond` production rule. The function `respond_action` performs two actions: (1) clear the visual buffer and (2) executes the function `responding!` which executes the motor response after a delay and calls the user-defined function `press_key`. The model uses `press_key` to interact with the task and collect data.  

```julia 
function respond_action(actr, task)
    clear_buffer!(actr.visual)
    key = "sb"
    responding!(actr, task, key)
    return nothing
end
```

## Construct Production Rules

The constructor `Rule` creates a production rule from the following keyword arguments: 

- `conditions`: a list of functions representing selection conditions
- `action`: a function that performs the actions of the production rule
- `actr`: a reference to the `ACTR` model object
- `task`: a reference to the PVT task
- `name`: an optional name for the production rule

Each production rule is pushed into a vector located in the `procedural` memory object.

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
Now that the model and task have been defined, we can now run the model simulation. A GUI will appear upon running the following code:

```julia
run!(actr, task)
```
