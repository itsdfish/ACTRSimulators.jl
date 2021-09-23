using SafeTestsets

@safetestset "Visual" begin include("visual_test.jl") end

@safetestset "Visual Location" begin include("visual_location_test.jl") end

@safetestset "Declarative" begin include("declarative_test.jl") end

@safetestset "Imaginal" begin include("imaginal_test.jl") end

@safetestset "Motor" begin include("motor_test.jl") end

@safetestset "Parallel" begin include("parallel_test.jl") end

@safetestset "Two Models" begin include("two_models.jl") end

@safetestset "Utility Noise" begin include("utility_noise.jl") end