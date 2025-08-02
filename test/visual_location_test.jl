using ACTRSimulators, Test, ACTRModels, Random, DataFrames
import ACTRSimulators: start!, press_key!
Random.seed!(8985)
include("task.jl")

scheduler = ACTRScheduler(; model_trace = true, store = true)
task = SimpleTask(; scheduler)
procedural = Procedural()
T = vo_to_chunk() |> typeof
visicon = VisualObject[]
visual_location = VisualLocation(buffer = T[])
visual = Visual(buffer = T[])
motor = Motor()
memory = [Chunk(; animal = :dog), Chunk(; animal = :cat)]
declarative = Declarative(; memory)
actr = ACTR(; scheduler, procedural, visual_location, visual, motor, declarative, visicon)

function can_stop(actr)
    c1(actr) = !actr.visual_location.state.empty
    return (c1,)
end

function stop(actr, task)
    stop!(actr.scheduler)
end

rule1 = Rule(; conditions = can_stop, action = stop, actr, task, name = "Stop")
push!(procedural.rules, rule1)
run!(actr, task)
chunk = actr.visual_location.buffer[1]
@test chunk.slots == (color = :black, text = "hello", x = 300.0, y = 300.0)

observed = map(x -> x.description, scheduler.complete_events)
expected = [
    "Starting",
    "Present Stimulus",
    "Selected Stop"
]
@test expected == observed
