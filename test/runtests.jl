tests = [
    "simulator",
    ]

for test in tests
    include(test * ".jl")
end
