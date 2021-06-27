import ACTRSimulators: start!
using ACTRSimulators, Test, ACTRModels, Random
Random.seed!(8985)
include("task.jl")

scheduler = ACTRScheduler(;model_trace=true, store=true)
task = SimpleTask(;scheduler)
procedural = Procedural()
T = vo_to_chunk() |> typeof
memory = [Chunk(;animal=:dog), Chunk(;animal=:cat)]
declarative = Declarative(;memory)
visicon = VisualObject[]
visual_location = VisualLocation(buffer=T[])
visual = Visual(buffer=T[])
motor = Motor()

actr = ACTR(;scheduler, procedural, visual_location, visual, motor, declarative, visicon)

function can_attend(actr)
    c1(actr) = !isempty(actr.visual_location.buffer)
    c2(actr) = !actr.visual.state.busy
    return all_match(actr, (c1,c2))
end    

function can_stop(actr)
    c1(actr) = !actr.visual.state.empty
    return all_match(actr, (c1,))
end

function attend_action(actr, task)
    buffer = actr.visual_location.buffer
    chunk = deepcopy(buffer[1])
    clear_buffer!(actr.visual_location)
    attending!(actr, chunk)
    return nothing
end

function stop(actr, task)
    stop!(actr.scheduler)
end

rule1 = Rule(;conditions=can_attend, action=attend_action, actr, task, name="Attend")
push!(procedural.rules, rule1)

rule2 = Rule(;conditions=can_stop, action=stop, actr, task, name="Stop")
push!(procedural.rules, rule2)
run!(actr, task)
chunk = actr.visual.buffer[1]
@test chunk.slots == (color = :black, text = "hello", x = 300.0, y = 300.0)

observed = map(x->x.description, scheduler.complete_events)
expected = [
    "Starting", 
    "Present Stimulus",
    "Selected Attend",
    "Attend", 
    "Selected Stop"
]
@test expected == observed