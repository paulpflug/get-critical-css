#!/usr/bin/env node

try {
  require("coffeescript/register")
  require("./src/cli.coffee")()
} catch (e) {
  require("./lib/cli.js")()
}
