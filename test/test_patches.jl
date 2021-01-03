using Test
using GatherShot
using Vimes


function tmpstring(f::Function, body)
    fn = "$(tempname()).jl"
    write(fn, body)
    try
        f(fn)
    catch
        rethrow()
    finally
        rm(fn)
    end
end


@testset "flipcond finds the less-than" begin
egi = quote
    if x > 3
        7
    end
    54
end
@test GatherShot.show_replacements(egi, [Vimes.flipcond])
end


@testset "flipcond runs after replacement" begin
eg_flipcond = """
function eg_func(x)
if x > 2
    9
else
    1
end
end
"""
tmpstring(eg_flipcond) do fn
    found, original, mutated = GatherShot.check_replacement(fn, Vimes.flipcond)
    @test found
    @test original != mutated
end
end


@testset "conditionals_boundary finds" begin
egi = quote
    if x > 3
        7
    end
    54
end
@test GatherShot.show_replacements(egi, [GatherShot.conditionals_boundary])
end


@testset "conditionals_boundary runs after replacement" begin
eg = """
function eg_func(x)
if x > 3
    9
else
    1
end
end
"""
tmpstring(eg) do fn
    found, original, mutated = GatherShot.check_replacement(fn, GatherShot.conditionals_boundary)
    @test found
    @test original != mutated
    end
end


@testset "invert_negatives finds a negative" begin
neg_example = quote
    a = 3
    b = -a
    c = 7 - b
end
@test GatherShot.show_replacements(neg_example, [GatherShot.invert_negatives])
end


@testset "invert_negatives runs after replacement" begin
eg = """
function eg_func(x)
    a = 6
    b = -a
    x + b
end
"""
tmpstring(eg) do fn
    found, original, mutated = GatherShot.check_replacement(fn, GatherShot.invert_negatives)
    @test found
    @test original != mutated
    end
end


@testset "math_mutator finds signs" begin
neg_example = quote
    a = 3
    b = -a
    c = 7 - b
end
@test GatherShot.show_replacements(neg_example, [GatherShot.math_mutator])
end


@testset "math_mutator runs after replacement" begin
eg = """
function eg_func(x)
    b = 7
    x - b
end
"""
tmpstring(eg) do fn
    found, original, mutated = GatherShot.check_replacement(fn, GatherShot.math_mutator)
    @test found
    @test original != mutated
end
end


@testset "empty_return finds return" begin 
return_eg = quote
    x = 2
    return x
end
@test GatherShot.show_replacements(return_eg, [GatherShot.empty_returns])
end


@testset "flip_returns finds return" begin 
return_eg = quote
    x = 2
    return x
end
@test GatherShot.show_replacements(return_eg, [GatherShot.flip_returns])
end


@testset "flip_returns runs after replacement" begin
eg = """
function eg_func(x)
    return x == 3
end
"""
tmpstring(eg) do fn
    found, original, mutated = GatherShot.check_replacement(fn, GatherShot.flip_returns)
    @test found
    @test original != mutated
end
end


@testset "return_nothing finds return" begin 
return_eg = quote
    x = 2
    return x
end
@test GatherShot.show_replacements(return_eg, [GatherShot.return_nothing])
end


@testset "return_nothing runs after replacement" begin
eg = """
function eg_func(x)
    return 3*x
end
"""
tmpstring(eg) do fn
    found, original, mutated = GatherShot.check_replacement(fn, GatherShot.return_nothing)
    @test found
    @test original != mutated
end
end


@testset "increment_integer finds integer" begin
    integer_eg = quote
        x = 3
        x
    end
    @test GatherShot.show_replacements(
        integer_eg,
        [GatherShot.increment_integer]
    )
end


@testset "increment_integer runs after replacement" begin
eg = """
function eg_func(x)
    a = 7
    return x + a
end
"""
tmpstring(eg) do fn
    found, original, mutated = GatherShot.check_replacement(fn, GatherShot.increment_integer)
    @test found
    @test original != mutated
end
end


@testset "decrement_integer finds integer" begin
    integer_eg = quote
        x = 3
        x
    end
    @test GatherShot.show_replacements(
        integer_eg,
        [GatherShot.decrement_integer]
    )
end


@testset "scale_float finds a float" begin
    float_eg = quote
        x = 3.2
        x
    end
    @test GatherShot.show_replacements(
        float_eg,
        [GatherShot.scale_float]
    )
end


@testset "scale_float runs after replacement" begin
eg = """
function eg_func(x)
    return x + 7.9
end
"""
tmpstring(eg) do fn
    found, original, mutated = GatherShot.check_replacement(fn, GatherShot.scale_float)
    @test found
    @test original != mutated
end
end


@testset "flip_and_or finds and" begin
condeg = quote
    a && b
end
@test GatherShot.show_replacements(
    condeg,
    [GatherShot.flip_and_or]
)
end
