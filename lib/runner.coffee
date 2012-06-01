phantom = require "phantom"
assert  = require "assert"
require "colors"

failures = []
passes   = []
allTests = []
pages    = []

# dirty variable to keep track of any tests added by the current
# addPage callback
tests    = []

Runner =
    addPage: (url, cb) ->
        page =
            url: url
            cb: cb

        pages.push page


    pageTests: []

    assertStyle: (selector, property, expected) ->
        test =
            selector: selector
            property: property
            expected: expected
            page: null
            url: null

        Runner.pageTests.push test

    start: ->
        phantom.create (ph) ->
            queuePages ph, pages


queuePages = (ph, _pages) ->
    if _pages.length is 0
        return runTests ph, allTests

    page = _pages.shift()

    ph.createPage (_page) ->
        _page.open page.url, (status) ->

            # the way we queue tests is a bit grim, by dumping asserts
            # into this variable. Hence before each callback it needs emptying
            Runner.pageTests = []

            # only once we have an actual page can we add the
            # assertions in a user's callback.
            page.cb()

            # queue up each test added by the callback against the
            # phantomjs page instance
            for test in Runner.pageTests
                test.page = _page
                test.url  = page.url
                
                allTests.push test

            # loop back through
            queuePages ph, _pages

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
