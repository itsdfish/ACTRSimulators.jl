"""
    fire!(actr)

Selects a production rule and registers conflict resolution and new events for selected production rule

# Arguments 

- `actr`: an ACT-R model object 
"""
function fire!(actr::AbstractACTR)
    actr.procedural.state.busy ? (return nothing) : nothing
    rules = actr.parms.select_rule(actr)
    isempty(rules) ? (return nothing) : nothing
    rule = rules[1]
    description = "Selected "*rule.name
    type = "model"
    id = get_name(actr)
    tΔ = rnd_time(.05)
    resolving(actr, true)
    f(r, a, v) = (resolving(a, v), r.action()) 
    register!(actr, f, after, tΔ, rule, actr, false; description, type, id)
    return nothing 
end

resolving(actr, v) = actr.procedural.state.busy = v

function compute_utility!(actr)
    #@unpack σu, δu = actr.parms
    δu = 1.0
    σu = .5
    for r in get_rules(actr)
        c = count_mismatches(r)
        u = rand(Normal(c * δu, σu))
        r.utility = u
    end
end
  
function count_mismatches(rule)
    return count(c->!c(), rule.conditions)
end
