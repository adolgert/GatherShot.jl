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

            reset(parent, child, relpath)
            @test readline(other) == "original"
        end
    end
end


@testset "new xml is one more than old xml" begin
    @test next_log(["f017.xml", "g001.xml"]) == 18
end
