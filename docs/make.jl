using GatherShot
using Documenter

makedocs(;
    modules=[GatherShot],
    authors="adolgert <adolgert@uw.edu>",
    repo="https://github.com/adolgert/GatherShot.jl/blob/{commit}{path}#L{line}",
    sitename="GatherShot.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://adolgert.github.io/GatherShot.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Usage" => "man/usage.md"
    ],
)

deploydocs(;
    devbranch = "main",
    repo="github.com/adolgert/GatherShot.jl",
    deploy_config=Documenter.GitHubActions()
)
