# Usage

In order to test a project, we need to run its unit tests many times on mutated code. We'll start with a local copy of the package. Then let the unit tests run and rerun for a while. Finally, process results.


## Check out the test suite to a local directory
Ensure there is a local copy of the package.
```cmd
git clone https://github.com/user/APackage.jl ~/dev/APackage
```

## Check that the test suite is suitable for test selection

There are a few ways that a test suite might not have the information in it that this technique needs.

1. There could be very few tests. There's no reason to select tests to run if there are very few of them.

2. All of the tests may be in one test set. There may be many calls to `@test`, but there is no way to distinguish the start of one test set and the end of another. If that's the case, then there is no way to determine which sets of tests pass or fail. The individual `@test` calls don't carry much meaning.

## Patch Vimes and TestReports

This is the new `apply!` in `patch.jl` of Vimes.
```julia
function apply!(f, path, patch)
  sourcemap(f) do ex
    pathwalk(ex) do p, x
      p == path ? patch(x) : x
    end
  end
  f, patch
end
```
And `TestReports.jl` keeps trying to eval the error codes, which fails here. So this is the change to `to_xml.jl` because I don't care why it got an error, just that it got an error.
```julia
function get_error_info(v::Error)
    if v.test_type == :test_nonbool
        msg = "Expression evaluated to non-Boolean"
        type = "Expression evaluated to non-Boolean"
    elseif v.test_type == :test_unbroken
        msg = "Got correct result, please change to @test if no longer broken."
        type = "Unexpected Pass"
    elseif v.test_type == :nontest_error
        msg = "Got exception outside of a @test"
        type = "nontest_error"  #typeof(eval(Meta.parse(v.value)))
    else
        err = "unknown_error"  #eval(Meta.parse(v.value))
        msg = "unknown_error"  #sprint(showerror, err)
        type = "unknown_error"  # typeof(err)
    end
    return msg, type
end
```

## Set up the GatherShot application.

You can install GatherShot into the base Julia install with
```julia
Pkg.add("GatherShot")
```
If you would prefer to work in an environment, then create a directory, such as `~/working`, and install there.
```julia
working = "~/working"
mkdir(working) && cd(working)
Pkg.activate(".")
Pkg.add("GatherShot")
```

We want unit tests to run as quickly as possible, so it helps to install into `~/working` all of the package dependencies of the package we will test. Look up the `Project.toml` of the package to test and add those dependencies.


## Start gathering data on the unit test coverage
This will run the unit tests 100 times.
```julia
using GatherShot
GatherShot.generate_reports("~/dev/APackage", 100)
```
The 100 runs may not be enough, but you'll know when you look at the data. This step can have problems.

1. A mutation can cause the unit tests to fail to return. In this case, use Ctrl-C and restart.

2. There may be few unit tests that fail. Sometimes it works out this way, depending on the unit tests. As a result, there will be very little data generated.


## Process the results

There are two steps to look at the results. First read all of the reports into a matrix of `outcomes`. The size of this matrix is the number of unit tests by the number of times the unit tests were run. The `key` is a dictionary from the name of the test to its integer index in the matrix rows.
```julia
outcomes, key = GatherShot.read_reports(dir)
chosen = GatherShot.select_tests(outcomes)
```
The `chosen` array is a list of the indices of a set of tests that will always find every mutation that was tried.


## Run only those tests that were chosen

This may require some engineering in order to make it work with the default Julia Test package. You have to store the list of tests to run and then select only those.
