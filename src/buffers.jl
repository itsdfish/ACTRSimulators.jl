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

# Arguments 

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

# Arguments 

- `mod`: a module
- `chunk`: a memory chunk 
"""
function add_to_buffer!(mod::Mod, chunk)
    remove_chunk!(mod)
    push!(mod.buffer, chunk)
end