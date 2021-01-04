# Given a project on disk, loop through mutations and runs of unit tests.

using Logging
using Pkg
using TestReports
using SourceWalk
using Vimes


"""Replace a mutated file with an original file"""
function reset(dir, tmp, f)
    relative_f = f[length(tmp) + 2:end]
    rm(f)
    cp(joinpath(dir, relative_f), f)
    return
end


function mutate_and_reset(callback::Function, dir, tmp, idx)
    f = nothing
    patch = nothing
    diff_pairs = Any[]
    while isempty(diff_pairs)
      f, patch = Vimes.mutate(tmp, idx)
      diff_pairs = Vimes.diff(dir, tmp)
    end
    if isnothing(f)
        diff_pairs = Vimes.diff(dir, tmp)
        error("Starting with a diff $(diff_pairs)")
    end
    println("Chose diff of $(f) $(String(Symbol(patch))): $(diff_pairs)")
    callback()
    reset(dir, tmp, f)
end


function initialise_noclean(dir)
    (isfile(joinpath(dir, "Project.toml")) && isdir(joinpath(dir, "src"))) ||
      error("No Julia project found at $dir")
    tmp = joinpath(tempdir(), "vimes-$(rand(UInt64))")
    mkdir(tmp)
    for path in readdir(dir)
        if !startswith(path, ".")
            cp(joinpath(dir, path), joinpath(tmp, path))
        end
    end
    return tmp
end


function setup_working(project_dir)
    pkgname = splitext(basename(project_dir))[1]
    copy_dir = initialise_noclean(expanduser(project_dir))
    # TestReports expects the package to be installed in order to test it.
    if !isnothing(Base.find_package(pkgname))
        Pkg.rm(pkgname)
    end
    Pkg.develop(path = copy_dir)
    Pkg.status()
    (copy_dir, pkgname)
end


function teardown_working(copy_dir, pkgname)
    Pkg.rm(pkgname)
    rm(copy_dir, recursive=true)
end


"""
For some reason, this creates a test log only once, the first time it is called.
It makes that log in the directory of the project itself. It makes another, empty
log in the current directory. The empty log always says there were no failures.
I can't figure out why it won't write another log.
"""
function run_testreports(pkgname)
    try
        run(`$(Base.julia_cmd()) --project=. -e "using TestReports; TestReports.test($(repr(pkgname)))"`)
    catch e
        if e isa ProcessFailedException
            false
        else
            throw(e)
        end
    end
    true
end


function next_log(file_list)
    xml_files = filter(x->endswith(x, ".xml"), file_list)
    length(xml_files) == 0 && return 1
    maximum(map(x -> parse(Int, match(r"[0-9]+", x).match),
                xml_files)) + 1
end


function generate_mutation_reports(project_dir, tmp, cnt::UnitRange, pkgname, logdir = pwd())
    patches = Any[
        Vimes.rmline, Vimes.flipcond,
        conditionals_boundary, invert_negatives, math_mutator, flip_returns,
        return_nothing, increment_integer, decrement_integer, scale_float, flip_and_or
    ]
    mutant_index = Vimes.indices(joinpath(tmp, "src"), patches)
    begin_idx = next_log(readdir(logdir))
    for mutation_idx in cnt .+ begin_idx
        #`$(Base.julia_cmd()) --project=$tmp -e 'using Pkg; Pkg.test()'`
        mutate_and_reset(project_dir, tmp, mutant_index) do
            testlog = joinpath(tmp, joinpath(logdir, "log$(lpad(mutation_idx, 5, "0")).xml"))
            runonce(tmp, testlog, pkgname)
        end
    end
end


function generate_reports(project_dir, cnt)
    project_dir = expanduser(project_dir)
    isdir(project_dir) || error("Cannot find directory $(project_dir)")
    project_copy, pkgname = setup_working(project_dir)
    println("cnt is $cnt")
    generate_mutation_reports(project_dir, project_copy, 1:cnt, pkgname)
    teardown_working(project_copy, pkgname)
end


"""
This is a small equivalent to TestReports.test(["BijectiveHilbert"]).
It's here because that function seems to write only one report
and won't write a second one.
"""
function runonce(tmp, logfile, pkgname)
    runtests = joinpath(tmp, "test", "runtests.jl")
    runner_code = """
using Test
using TestReports
using $(pkgname)

append!(empty!(ARGS), String[])

ts = @testset ReportingTestSet "" begin
    include($(repr(runtests)))
end

write($(repr(logfile)), report(ts))
"""
    println(runner_code)
    test_process = open(`$(Base.julia_cmd()) --project=. -e $(runner_code)`, read = false)
    # Let the existence of the XML report tell us success or failure.
    wait(test_process)
end
