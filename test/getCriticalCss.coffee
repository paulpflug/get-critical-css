{test} = require "snapy"

getCriticalCss = require "../src/cli.coffee"

test (snap) ->
  getCriticalCss.run()
  .then =>
    snap file:"./app_build/_critical.css"
    snap file:"./app_build/_uncritical.css"
    .then ({value}) =>
      snap file:"./app_build/#{value}"
      snap file:"./app_build/#{value}.gz", encoding: "hex"
      snap file:"./app_build/#{value}.br", encoding: "hex"
