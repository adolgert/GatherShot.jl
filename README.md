# GatherShot

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://adolgert.github.io/GatherShot.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://adolgert.github.io/GatherShot.jl/dev)
[![Build Status](https://github.com/adolgert/GatherShot.jl/workflows/CI/badge.svg)](https://github.com/adolgert/GatherShot.jl/actions)

GatherShot analyzes unit tests in order to select fewer tests that find the same faults.

1. Pick a project to analyze.
2. This runs the project's unit tests over and over.
3. Each time, it intentionally creates a bug and watches which unit tests fail.
4. It reports what subset of unit tests find all failures.
5. You tell the testing framework to execute only those tests.
