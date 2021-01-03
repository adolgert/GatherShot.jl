# This adds mutators to the Vimes.jl library.
# It uses this as a guide:
# http://pitest.org/quickstart/mutators/
using InteractiveUtils
using SourceWalk
using Vimes


# Checks whether a library replacement works on a given expression.
function show_replacements(ex, fs)
    match_any = false
    Vimes.pathwalk(ex) do p, x
      for f in fs
        if Vimes.matches(f, x)
          println("starts as $(x)")
          println("matches to $(f(x))")
          match_any = true
        end
      end
      return x
    end
    match_any
end


"""
    check_replacement(example_file, mutation)

Check that a patch works on a file and runs when patched.
The `example_file` is the path to a file to mutate.
The mutation is a single mutation function. The example
file must contain a function called `eg_func` that has
a single argument. It will be called with `eg_func(3)`
and should return one value unmutated and a different
value when mutated.
"""
function check_replacement(example_file, mutation)
    include(example_file)
    original_result = Base.invokelatest(eg_func, 3)

    pf = Vimes.parsefile(example_file)
    fidx = Vimes.index(pf, [mutation])
    length(fidx) > 0 || return (false, original_result, nothing)
    mut_fn = "$(tempname()).jl"
    cp(example_file, mut_fn, force = true)
    path, patch = first(fidx)
    Vimes.apply!(mut_fn, path, patch[1])

    mutated_result = original_result
    try
        include(mut_fn)
        mutated_result = Base.invokelatest(eg_func, 3)
    catch e
        rethrow()
    finally
        rm(mut_fn)
    end
    (true, original_result, mutated_result)
end


# Turns > into >=, >= into >. The same for less-than.
function conditionals_boundary(x)
    if isexpr(x, :call)
        if x.args[1] == :>
            Expr(x.head, :>=, x.args[2:end]...)
        elseif x.args[1] == :>=
            Expr(x.head, :>, x.args[2:end]...)
        elseif x.args[1] == :<
            Expr(x.head, :<=, x.args[2:end]...)
        elseif x.args[1] == :<=
            Expr(x.head, :<, x.args[2:end]...)
        else
            nothing
        end
    else
        nothing
    end
end


# This takes the unary - to a positive.
function invert_negatives(x)
    isexpr(x) && x.args[1] == :- && length(x.args) == 2 || return
    x.args[2]
end


# Turns + -> -, - -> +, etc, for integer and float.
function math_mutator(x)
    isexpr(x) && length(x.args) == 3 || return
    a, b = x.args[2:3]
    if x.args[1] == :-
        :(isa($a, Real) && isa($b, Real) ? $a + $b : $x)
    elseif x.args[1] == :+
        :(isa($a, Real) && isa($b, Real) ? $a - $b : $x)
    elseif x.args[1] == :*
        :(isa($a, Real) && isa($b, Real) ? $a / $b : $x)
    elseif x.args[1] == :/
        :(isa($a, Real) && isa($b, Real) ? $a * $b : $x)
    elseif x.args[1] == :%
        :(isa($a, Real) && isa($b, Real) ? $a * $b : $x)
    elseif x.args[1] == :*
        :(isa($a, Real) && isa($b, Real) ? $a % $b : $x)
    elseif x.args[1] == :^
        :(isa($a, InteRealger) && isa($b, Real) ? $a * $b : $x)
    elseif x.args[1] == :&
        :(isa($a, Integer) && isa($b, Integer) ? $a | $b : $x)
    elseif x.args[1] == :|
        :(isa($a, Integer) && isa($b, Integer) ? $a & $b : $x)
    elseif x.args[1] == :<<
        :(isa($a, Integer) && isa($b, Integer) ? $a >> $b : $x)
    elseif x.args[1] == :>>
        :(isa($a, Integer) && isa($b, Integer) ? $a << $b : $x)
    elseif x.args[1] == :>>>
        :(isa($a, Integer) && isa($b, Integer) ? $a << $b : $x)
    else
        nothing
    end
end


function incode_math_mutator(a, b)
    isa(a, Real) && isa(b, Real) ? a - b : a + b
end


empty_return(x::AbstractString) = ""
empty_return(x::Real) = zero(x)
empty_return(x::Set{T}) where {T} = Set{T}()
empty_return(x::Array{T,1}) where {T} = Array{T,1}()
empty_return(x::Dict{K,V}) where {K,V} = Dict{K,V}()
empty_return(x::Char) = '\0'
empty_return(x) = x


function empty_returns(x)
    isexpr(x, :return) || return
    Expr(:return, Expr(:call, :empty_return, x.args[1]))
end

flip_return(x::Bool) = !x
flip_return(x) = x

function flip_returns(x)
    isexpr(x, :return) || return
    Expr(:return, Expr(:call, :flip_return, x.args[1]))
end


function return_nothing(x)
    isexpr(x, :return) && x.args[1] !== nothing || return
    Expr(:return, nothing)
end


function increment_integer(x)
    x isa Integer && !(x isa Bool) && return x + 1
end

function decrement_integer(x)
    x isa Integer && !(x isa Bool) && return x - 1
end


function scale_float(x)
    x isa AbstractFloat && return 0.9 * x
end


function flip_and_or(x)
    isexpr(x, :&&) && return Expr(:||, x.args...)
    isexpr(x, :||) && return Expr(:&&, x.args...)
end
