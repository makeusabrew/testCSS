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
        tests.push test

    start: ->
        opened = 0
        phantom.create (ph) ->
            for page in pages
                do (page) ->
                    ph.createPage (_page) ->
                        _page.open page.url, (status) ->
                            page.cb()
                            queueTests _page
                            opened += 1
                            if opened is pages.length
                                runTests ph


queueTests = (page) ->
    for test in tests
        test.page = page
        allTests.push test

    tests = []

runTests = (ph) ->
    for test in allTests
        actuallyAssert test.page, test.selector, test.property, test.expected, (ok) ->
            if not ok
                failures.push(test)
                process.stdout.write(".".red)
            else
                passes.push(test)
                process.stdout.write(".".green)

            testsRun += 1
            if testsRun is allTests.length
                process.stdout.write "\n"
                console.log "#{passes.length} passes, #{failures.length} failures"
                ph.exit()

actuallyAssert = (page, selector, property, expected, cb) ->
    evaluate page, (actual) ->
        cb(actual is expected)

    , (selector, property) ->
        content = document.getElementById(selector)
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
