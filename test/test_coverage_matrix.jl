using Test
using GatherShot


@testset "select_tests finds simplest" begin
    @test GatherShot.select_tests(Bool[1]) == [1]
end


@testset "select_tests gets independent" begin
    outcomes = Bool[
        1 0 0;
        0 1 0;
        0 0 1
    ]
    @test GatherShot.select_tests(outcomes) == [1, 2, 3]
end


@testset "select_tests ignores non-dominant" begin
    outcomes = Bool[
        1 0 0;
        1 1 0;
        0 0 1
    ]
    @test GatherShot.select_tests(outcomes) == [2, 3]
end
