module ACTRSimulators
    using Reexport
    @reexport using DiscreteEventsLite, ACTRModels
    using ACTRModels, DiscreteEventsLite, DataStructures, CodeTracking
    import DiscreteEventsLite: run!, last_event!, is_running, print_event, register!
    import DiscreteEventsLite: Now, At, After, Every, AbstractScheduler
    import ACTRModels: AbstractACTR, utility_match
    export run!, next_event!, register!, vo_to_chunk, add_to_visicon!, clear_buffer!, add_to_buffer!, get_time, attending!
    export attend!, retrieving!, retrieve!, responding!, respond!
    export encoding!, encode!, all_match, AbstractTask, ACTRScheduler, setup_window, import_gui
    export remove_visual_object!, clear_visicon!, move_vo!
    export repaint!, draw_object!, clear!, draw_attention!, why_not
    
    include("simulator.jl")
    include("buffers.jl")
    include("declarative.jl")
    include("imaginal.jl")
    include("visual.jl")
    include("motor.jl")
    include("procedural.jl")
    include("utilities.jl")
end
