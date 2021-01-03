@testset "select_tests finds simplest" begin
    @test select_tests([1]) == 1
end


@testset "select_tests gets independent" begin
    outcomes = [
        1 0 0;
        0 1 0;
        0 0 1
    ]
    @test select_tests(outcomes) == [1, 2, 3]
end


@testset "select_tests ignores non-dominant" begin
    outcomes = [
        1 0 0;
        1 1 0;
        0 0 1
    ]
    @test select_tests(outcomes) == [1, 3]
end
