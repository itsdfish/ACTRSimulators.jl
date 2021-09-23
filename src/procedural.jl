"""
    fire!(actr)

Selects a production rule and registers conflict resolution and new events for selected production rule

# Arguments 

- `actr`: an ACT-R model object 
"""
function fire!(actr::AbstractACTR)
    actr.procedural.state.busy ? (return nothing) : nothing
    rules = select_rule(actr)
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

function select_rule(actr)
    rules = get_rule_set(actr)
    isempty(rules) ? (return rules) : nothing
    compute_utilities!(actr, rules)
    _,idx = findmax(x -> x.utility, rules)
    return rules[idx:idx]
end

function get_rule_set(actr)
    @unpack mmp_utility = actr.parms
    rules = get_rules(actr)
    if mmp_utility
        # use @code_string to filter out conditions that do not contain
        # slots. Consider caching a boolean that indicates whether a production
        # rule is eligible for partial matching
        return rules 
    end 
    return filter(r->match(actr, r), rules)
end

get_rules(actr) = actr.procedural.rules

function match(actr, rule)
    return all_match(actr, rule.conditions)
end

"""
    all_match(actr, conditions) 

Checks whether all conditions of a production rule are satisfied. 

# Arguments

- `actr`: an ACT-R model object
- `conditions`: a tuple of functions representing production rule conditions.
"""
function all_match(actr, conditions)    
    for c in conditions
        !c(actr) ? (return false) : nothing
    end
    return true
end

function compute_utilities!(actr, rules)
    for rule in rules
        compute_utility!(actr, rule)
    end
    return nothing
end

function compute_utility!(actr, rule)
    @unpack utility_noise, mmp_utility = actr.parms
    mmp_utility ? compute_penalties!(actr, rule) : nothing
    utility_noise ? add_noise!(actr, rule) : nothing 
    total_utility!(rule)
end
  
function compute_penalties!(actr, rule)
    @unpack model_trace = actr.scheduler
    @unpack δu,util_mmp_fun = actr.parms
    model_trace ? println("rule: ", rule.name) : nothing
    penalty = 0.0
    for c in rule.conditions
        penalty += util_mmp_fun(actr, c)
    end
    model_trace ? println("") : nothing
    rule.utility_penalty = penalty * δu
    return nothing
end

function utility_match(actr::ACTR, condition)
    @unpack model_trace = actr.scheduler
    penalty = condition(actr) ? 0.0 : 1.0
    model_trace ? condition_trace(actr, condition, penalty) : nothing
    return penalty
end

function condition_trace(actr, condition, penalty)
    str = @code_string condition(actr) 
    println(str)
    println("penalty: $penalty")
    return nothing 
end

function add_noise!(actr, rule)
    @unpack σu = actr.parms
    rule.utility_noise = rand(Normal(0, σu))
end

function total_utility!(r::Rule)
    r.utility_mean = r.initial_utility + r.utility_penalty
    r.utility = r.utility_mean + r.utility_noise
    return nothing 
end

function Rule(;
    utility = 0.0,
    initial_utility = 0.0,
    utility_mean = 0.0,
    utility_penalty = 0.0,
    utility_noise = 0.0,
    conditions, 
    name = "", 
    actr, 
    task, 
    action, 
    args = (), 
    kwargs...
    )
    funs = conditions(actr, args...; kwargs...) 
    can_pm = can_partial_match(funs, actr) 
    Rule(
        utility, 
        initial_utility,
        utility_mean, 
        utility_penalty, 
        utility_noise, 
        conditions(actr, args...; kwargs...), 
        ()->action(actr, task; kwargs...),
        can_pm,
        name
     )
end

function can_partial_match(conditions, actr) 
    for c in conditions
        str = @code_string c(actr)
        !occursin("slots", str) ? (return false) : nothing 
    end
    return true
end