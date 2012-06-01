require "colors"

List =
    pass: (test) ->
        List.write "✔", test
    fail: (test) ->
        List.write "✘", test

    write: (symbol, test) ->
        console.log "#{symbol} #{test.url} - #{test.selector} - #{test.property}"

module.exports = List
