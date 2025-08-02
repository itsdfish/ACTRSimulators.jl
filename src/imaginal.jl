"""
    encoding!(actr, chunk, args...; kwargs...)

Sets imaginal module as busy and registers a new event to create a new `chunk`

# Arguments 

- `actr`: an ACT-R model object 
- `chunk`: a memory chunk 
"""
function encoding!(actr, chunk)
    actr.imaginal.state.busy = true
    description = "Create New Chunk"
    type = "model"
    id = get_name(actr)
    tΔ = rnd_time(0.200)
    register!(actr, encode!, after, tΔ, actr, chunk; id, description, type)
    return tΔ
end

"""
    encode!(actr, chunk, args...; kwargs...)

Completes the creation of a chunk and adds resulting `chunk` to the imaginal buffer. The buffer
states are set to busy = false and empty = false.

# Arguments 

- `actr`: an ACT-R model object 
- `chunk`: a memory chunk 
"""
function encode!(actr, chunk)
    actr.imaginal.state.busy = false
    actr.imaginal.state.empty = false
    add_to_buffer!(actr.imaginal, chunk)
    return nothing
end
