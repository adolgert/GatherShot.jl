using GatherShot
using Test

@testset "observe" begin include("test_observe.jl") end
@testset "patch" begin include("test_patches.jl") end
@testset "coverage" begin include("test_coverage_matrix.jl") end
