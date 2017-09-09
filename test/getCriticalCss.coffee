chai = require "chai"
should = chai.should()

getCriticalCss = require "../src/getCriticalCss.coffee"

html = """
<!DOCTYPE html>
<html>
<head>
  <style type="text/css">
    body {
      height: 20px
    }
    .not-used {
      height: 20px
    }
    @media only screen and (max-width :600px) {
      body {
        width: 20px
      }
      .not-used {
        width: 20px
      }
    }
  </style>
</head>
<body>
</body>
</html>
"""
chromeInstance = null
describe "getCriticalCss", =>
  it "should work", =>
    {critical, uncritical} = await getCriticalCss html: html
    critical.should.equal "body{height:20px;}"
    uncritical.should.equal ".not-used{height:20px}@media only screen and (max-width:600px){body{width:20px}.not-used{width:20px}}"