module GatherShot

include("patches.jl")
include("observe.jl")
include("coverage_matrix.jl")

export generate_reports
export read_reports
export select_tests
export empty_return
export flip_return

end
