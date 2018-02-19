{launch} = require "chrome-launcher"
remoteInterface = require "chrome-remote-interface"
parser = require "coverage-delta-parser"
util = require "util"

module.exports = (work, config) =>
  unless config?
    readConf = require "read-conf"
    config = await readConf 
      name: "critical-css.config"
      folders: ["./build","./"]
      schema: require.resolve("./configSchema")
  unless hadChrome = (chromeInstance = config.chromeInstance)?
    chromeInstance = await launch port: config.chromePort, chromeFlags: config.chromeFlags
  tab = await remoteInterface.New()
  {DOM, CSS, Emulation, Page} = await remoteInterface Object.assign({port: chromeInstance.port},target: tab)
  await Promise.all [DOM.enable(), CSS.enable(), Page.enable()]

  await CSS.startRuleUsageTracking()

  stylesheetUrlToId = {}
  idToOldId = {}
  styleSheetTexts = {}
  styleSheetLoaded = Promise.resolve()
  CSS.styleSheetAdded ({header}) =>
    newId = header.styleSheetId
    if (oldId = stylesheetUrlToId[header.sourceURL])?
      idToOldId[newId] = oldId
    else
      stylesheetUrlToId[header.sourceURL] = newId
      styleSheetLoaded = styleSheetLoaded
        .then => CSS.getStyleSheetText styleSheetId: newId
        .then ({text}) => styleSheetTexts[newId] = text


  mergedCoverage = []
  mergeCoverage = =>
    {coverage} = await CSS.takeCoverageDelta()
    for cov in coverage
      found = false
      if (id = idToOldId[cov.styleSheetId])
        cov.styleSheetId = id
        for oldCov in mergedCoverage
          if oldCov.styleSheetId == id and 
            oldCov.startOffset <= cov.endOffset and
            oldCov.endOffset >= cov.startOffset
              found = true
              oldCov.startOffset = Math.min(oldCov.startOffset, cov.startOffset)
              oldCov.endOffset = Math.max(oldCov.endOffset, cov.endOffset)
              break
      mergedCoverage.push cov unless found

  wait = => new Promise (resolve) => setTimeout resolve, config.delay
  
  for route in work.routes
    await Page.navigate url: "http://"+config.host+route
    await Page.loadEventFired()
    await Page.frameStoppedLoading()
    # console.log util.inspect(await DOM.getDocument({depth:10}), {depth:10})
    await wait()
    for profile in config.profiles
      await Emulation.setDeviceMetricsOverride Object.assign { 
        mobile: false
        deviceScaleFactor: 0
        fitWindow: false
        }, profile
    await mergeCoverage()
    await styleSheetLoaded
  return {} unless mergedCoverage.length > 0
    
  parser 
    coverage: mergedCoverage
    CSS: getStyleSheetText: ({styleSheetId}) => text: styleSheetTexts[styleSheetId]
    minify: config.minify
  .then (result) =>
    await remoteInterface.Close({id: tab.id})
    await chromeInstance.kill() unless hadChrome
    return result

  