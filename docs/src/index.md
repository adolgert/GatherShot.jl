```@meta
CurrentModule = GatherShot
```

# GatherShot

GatherShot analyzes unit tests in order to select fewer tests that find the same faults. It measures test coverage with mutation analysis from [Vimes.jl](https://github.com/MikeInnes/Vimes.jl).

The Julia testing environment doesn't have built-in support for selecting tests to run, so consider this work experimental.

1. Pick a project to analyze.
2. This runs the project's unit tests over and over.
3. Each time, it intentionally creates a bug and watches which unit tests fail.
4. It reports what subset of unit tests find all failures.
5. You tell the testing framework to execute only those tests.


# Installation

```julia
pkg> add BijectiveHilbert
pkg> add https://github.com/MikeInnes/Vimes.jl
```
You have to add `Vimes.jl` by hand because there is a non-working version on JuliaHub and a working version on GitHub.
