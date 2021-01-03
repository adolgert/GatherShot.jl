using Test
using GatherShot


@testset "reset mutated file" begin
    relpath = "sub/file.txt"
    mktempdir() do parent
        mkdir(joinpath(parent, dirname(relpath)))
        write(joinpath(parent, relpath), "original")
        mktempdir() do child
            mkdir(joinpath(child, dirname(relpath)))
            other = joinpath(child, relpath)
            write(other, "mutated")

            @test readline(other) == "mutated"
            GatherShot.reset(parent, child, other)
            @test readline(other) == "original"
        end
    end
end


@testset "new xml is one more than old xml" begin
    @test GatherShot.next_log(["f017.xml", "g001.xml"]) == 18
end
