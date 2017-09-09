{launch} = require "chrome-launcher"
remoteInterface = require "chrome-remote-interface"
parser = require "coverage-delta-parser"
{resolve} = require "path"
fs = require "fs-extra"
defaultFlags = ["--disable-gpu","--headless"]
defaultProfiles = [{
    width: 2560, height: 1440
  },{
    width: 1280, height: 1280
  },{
    width: 720, height: 1280, mobile: true
  },{
    width: 400, height: 800, mobile: true
  }]
module.exports = (opts) =>
  opts ?= {}
  flags = opts.chromeFlags or defaultFlags
  profiles = opts.profiles or defaultProfiles
  try
    chromeInstance = await launch chromeFlags: flags
    {DOM, CSS, Emulation, Page} = await remoteInterface port: chromeInstance.port
    await Promise.all [DOM.enable(), CSS.enable(), Page.enable()]
    {frameId} = await Page.navigate url: "about:blank"
    await CSS.startRuleUsageTracking()
    allStylesheets = []
    filteredStylesheets = []
    setHtml = (html) => new Promise (resolve, reject) =>
      stylecount = html.match(/<style[^>]*type=['"]text\/css['"][^>]*>/g).length
      i = 0
      # what if no stylesheet is added or changed?
      # how to detect html change..
      CSS.styleSheetAdded ({header}) => 
        allStylesheets.push header
        if ++i == stylecount
          for profile in profiles
            await Emulation.setDeviceMetricsOverride Object.assign { 
              mobile: false
              deviceScaleFactor: 0
              fitWindow: false
              }, profile
          setTimeout resolve, opts.delay or 1000
      await Page.setDocumentContent frameId: frameId, html: html
      setTimeout (=>
        reject() unless i >= stylecount
      ), opts.timeout or 10000
    filterStylesheets = =>
      if (filter = opts.stylesheets)?
        if typeof filter == "function"
          sheets = await filter(DOM)
        else
          document = await DOM.getDocument depth:1
          sheets = await DOM.querySelectorAll Object.assign document.root, selector: filter
          sheets = sheets.nodeIds
        backendNodeIds = allStylesheets.map (stylesheet) => stylesheet.ownerNode
        frontendNodeIds = await DOM.pushNodesByBackendIdsToFrontend backendNodeIds: backendNodeIds
        frontendNodeIds = frontendNodeIds.nodeIds
        for sheetId in sheets
          if ~(i = frontendNodeIds.indexOf(sheetId))
            filteredStylesheets.push allStylesheets[i]
      else
        filteredStylesheets = filteredStylesheets.concat allStylesheets
      allStylesheets = []
    if opts.html
      htmls = if Array.isArray(opts.html) then opts.html else [opts.html]
      for html in htmls
        await setHtml(html).then filterStylesheets

    {coverage} = await CSS.takeCoverageDelta()
    {critical, uncritical} = await parser 
      coverage: coverage
      CSS: CSS
      styleSheetIds: filteredStylesheets.map (stylesheet) => stylesheet.styleSheetId
      minify: opts.minify
  catch e
    console.log e

  await chromeInstance?.kill?()

  criticalCSS = critical.toString()
  uncriticalCSS = uncritical.toString()

  if opts.save
    resolveSave = resolve.bind(null,opts.save)
    critical = opts.criticalName or "_critical"
    uncritical = opts.uncriticalName or "_uncritical"
    writers = []
    write = (name, content) =>
      writers.push fs.outputFile resolveSave(name), content

    write critical+".css", criticalCSS

    unless opts.hash? and opts.hash == false
      {createHash} = require "crypto"
      hashed = createHash("md5").update(uncriticalCSS).digest('hex')+".css"
      write uncritical, hashed
    else
      hashed = uncritical+".css"
    write hashed, uncriticalCSS

    unless opts.compress? and opts.compress == false
      try 
        zlib = require "node-zopfli"
      catch
        zlib = require "zlib"
      writers.push new Promise((resolve, reject) =>
        zlib.gzip new Buffer(uncriticalCSS), (err, result) =>
          return reject(err) if err
          resolve(result)
        ).then (result) => write hashed+".gz", result

    await Promise.all(writers)
  return critical: criticalCSS, uncritical: uncriticalCSS

