require "colors"

Dot =
    pass: (test) ->
        process.stdout.write(".".green)
    fail: (test) ->
        process.stdout.write(".".red)

module.exports = Dot
