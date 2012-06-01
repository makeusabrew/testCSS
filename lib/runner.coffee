phantom = require "phantom"
assert = require "assert"
require "colors"

failures = []
passes = []
tests = []
allTests = []
testsRun = 0

pages = []

Runner =
    addPage: (url, cb) ->
        page =
            url: url
            cb: cb

        pages.push page

    assertStyle: (selector, property, expected) ->
        test =
            selector: selector
            property: property
            expected: expected
            page: null
            url: null

        tests.push test

    start: ->
        phantom.create (ph) ->
            queuePages ph, pages


queuePages = (ph, _pages) ->
    if _pages.length is 0
        return runTests ph, allTests

    page = _pages.shift()
    ph.createPage (_page) ->
        _page.open page.url, (status) ->
            page.cb()
            addTests _page, page.url
            queuePages ph, _pages

addTests = (page, url) ->
    for test in tests
        test.page = page
        test.url = url
        allTests.push test

    tests = []

runTests = (ph, _tests) ->
    return finish ph if _tests.length is 0

    test = _tests.shift()

    actuallyAssert test.page, test.selector, test.property, test.expected, (actual) ->
        test.actual = actual

        if test.expected is test.actual
            passes.push(test)
            process.stdout.write(".".green)
        else
            failures.push(test)
            process.stdout.write(".".red)

        testsRun += 1
        runTests ph, _tests

finish = (ph) ->
    process.stdout.write "\n"
    console.log "#{passes.length} passes, #{failures.length} failures"

    if failures.length
        process.stdout.write "\n"
        console.log "Failures:".red
        process.stdout.write "\n"

    for failure in failures
        console.log "URL: #{failure.url}: #{failure.actual} !== #{failure.expected}"
    ph.exit()

actuallyAssert = (page, selector, property, expected, cb) ->
    evaluate page, (actual) ->
        cb(actual)

    , (selector, property) ->
        content = document.querySelector(selector)
        window.getComputedStyle(content, null).getPropertyValue(property)
    , selector, property

evaluate = (page, cb, func) ->
    args = [].slice.call(arguments, 3)
    str = "function() { return (#{func.toString()})("
    for arg, i in args
        if /object|string/.test(typeof arg)
            str += 'JSON.parse(' + JSON.stringify(JSON.stringify(arg)) + '),'
        else
            str += arg + ','
    
    str = str.replace(/,$/, '); }')
    page.evaluate(str, cb)

module.exports = Runner
