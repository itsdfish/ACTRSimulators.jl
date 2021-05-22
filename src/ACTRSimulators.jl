module ACTRSimulators
    using ACTRModels, DiscreteEventsLite, DataStructures
    import DiscreteEventsLite: run!, last_event!, is_running, print_event
    export run!, vo_to_chunk, add_to_visicon!, clear_buffer!, add_to_buffer!, get_time, attending!
    export attend!, retrieving!, retrieve!, responding!, respond!, press_key!

    include("simulator.jl")
end
