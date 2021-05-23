module ACTRSimulators
    using Reexport
    @reexport using DiscreteEventsLite
    using ACTRModels, DiscreteEventsLite, DataStructures
    import DiscreteEventsLite: run!, last_event!, is_running, print_event
    export run!, vo_to_chunk, add_to_visicon!, clear_buffer!, add_to_buffer!, get_time, attending!
    export attend!, retrieving!, retrieve!, responding!, respond!, press_key!
    export encoding!, encode!

    include("simulator.jl")
end
