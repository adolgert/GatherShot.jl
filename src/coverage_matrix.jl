# Given test reports from unit test runs, select a subset of tests.
using EzXML


"""
    test_outcomes_from_xml(xmlpath)

Reads the XML from TestReports, which is a standard JUnit XML format.
The xmlpath is a document object model (DOM) from EzXML's `readxml()`.
Count each test suite as a unit test, not individual tests within
the test suite. Return a dictionary from test name to number of failures.
"""
function test_outcomes_from_xml(xmlpath)
    outcomes = Dict{String, Int}()
    for testsuite in findall("//testsuite", xmlpath)
        name = nothing
        failures = nothing
        for attrib in attributes(testsuite)
            if attrib.name == "name"
                name = attrib.content
            elseif attrib.name == "failures"
                failures = parse(Int, attrib.content)
            end
        end
        if !isnothing(name) && !isnothing(failures)
            outcomes[name] = failures
        end
    end
    outcomes
end


"""
    read_reports(dir)

Read unit test reports in a directory as a matrix of which passed and
failed for each run. This assumes every XML file in the directory is
a unit test log report.
"""
function read_reports(dir)
    reports = filter(x -> startswith(x, "log") && endswith(x, ".xml"), readdir(dir))
    sample = test_outcomes_from_xml(EzXML.readxml(joinpath(dir, first(reports))))
    println("sample $(sample)")
    outcomes = zeros(Bool, length(sample), length(reports))
    key = Dict{String, Int}((b, a) for (a, b) in enumerate(keys(sample)))

    for (report_idx, report) in enumerate(reports)
        log = EzXML.readxml(joinpath(dir, report))
        outcome = test_outcomes_from_xml(log)
        for (test_name, test_fails) in outcome
            if !haskey(key, test_name)
                # In case a test case was added mid-way through.
                key[test_name] = length(key) + 1
                next_outcomes = zeros(Bool, length(key), length(reports))
                next_outcomes[1:(length(key) - 1), :] .= outcomes
                outcomes = next_outcomes
            end
            outcomes[key[test_name], report_idx] = test_fails > 0
        end
    end
    (outcomes, key)
end


"""
    select_tests(outcomes)

Given a Bool array of pass/fail outcomes that is (test cases) x (test runs),
choose a subset of test cases that would have found every failure.

This is a greedy algorithm. It begins by choosing the test case that
caught the most failed tests. Then it forgets about those tests and
chooses the next test case that eliminated the most failed tests among the
remaining.
"""
function select_tests(outcomes)
    detected = outcomes[:, vec(sum(outcomes, dims = 1) .> 0)]
    choices = zeros(Int, size(outcomes, 1))
    choice_cnt = 0
    while sum(detected) > 0
        choice_cnt += 1
        choice = argmax(vec(sum(detected, dims = 2)))
        choices[choice_cnt] = choice
        detected = detected[:, .!detected[choice, :]]
    end
    choices[1:choice_cnt]
end
