module ACTRSimulators
    using Reexport
    @reexport using DiscreteEventsLite, ACTRModels
    using ACTRModels, DiscreteEventsLite, DataStructures
    import DiscreteEventsLite: run!, last_event!, is_running, print_event, register!
    import DiscreteEventsLite: Now, At, After, Every
    import ACTRModels: AbstractACTR
    export run!, next_event!, register!, vo_to_chunk, add_to_visicon!, clear_buffer!, add_to_buffer!, get_time, attending!
    export attend!, retrieving!, retrieve!, responding!, respond!
    export encoding!, encode!

    include("simulator.jl")
end
