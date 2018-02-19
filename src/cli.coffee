path = require "path"
readConf = require "read-conf"
fs = require "fs-extra"
{resolve} = require "path"
{launch} = require "chrome-launcher"

getCriticalCss = require "./getCriticalCss"
isString = (obj) => typeof obj == "string" or obj instanceof String
isArray = Array.isArray

module.exports = =>
  args = process.argv.slice(2)

  for arg,i in args
    arg = args[i]
    if arg[0] == "-"
      switch arg
        when '-h', "--help"
          console.log('usage: get-critical-css (config file)')
          console.log('')
          console.log('config file is optional and defaults to "critical-css.config.[js|json|coffee|ts]"')
          console.log('in "build/" and "/"')
          process.exit()
    else
      name = arg
  module.exports.run(name)
  .then (e) => 
    if e?
      process.exit(0)
    else
      process.exit(1)

    
module.exports.run = (name) =>
  chromeInstance = null
  leaInstance = null
  readConf 
    name: name or "critical-css.config"
    folders: ["./build","./"]
    schema: require.resolve("./configSchema")
    required: false
  .then ({config}) =>
    if (start = config.startUp)?
      stop = null
      starting = start((cb) => stop = cb) or Promise.resolve()
      config.host ?= "localhost:8080"
    else 
      Leajs = require "leajs"
      starting = Leajs.getConfig()
        .then (lea) =>
          leaInstance = lea
          lea.config.listen.host ?= "localhost"
          config.host ?= lea.config.listen.host+":"+lea.config.listen.port
          lea.startUp()
        .catch (e) =>
          console.log e
          config.host ?= "localhost:8080"
    unless (items = config.items)?
      items = [item = {}]
      {config: _routes} = await readConf
        name: "routes.config"
        folders: ["./server", "./"]
      item.routes = Object.keys(_routes)
    else
      for item,i in items
        if isString(item)
          items[i] = {routes:[item]}
        else if isArray(item)
          items[i] = {routes:item}
    chromeInstance = config.chromeInstance = await launch port: config.chromePort, chromeFlags: config.chromeFlags
    await starting
    chromeDone = []
    isDone = items.map (item) =>
      chromeDone.push (result = getCriticalCss(item, config))
      if chromeDone.length == items.length
        chromeDone = Promise.all(chromeDone)
          .then (test) => 
            Promise.all [
              chromeInstance.kill()
              leaInstance?.close()
            ]
      {critical, uncritical} = await result
      if critical or uncritical
        writers = []
        folder = item.folder or config.folder
        if critical
          criticalFile = item.files?.critical or config.files.critical
          writers.push fs.outputFile resolve(folder, criticalFile)+".css", critical
        if uncritical
          uncriticalFile = item.files?.uncritical or config.files.uncritical
          uncriticalFile = resolve(folder, uncriticalFile)+".css"
          if item.hash or (not item.hash? and config.hash)
            {createHash} = require "crypto"
            hashed = createHash("sha1").update(uncritical).digest('hex')+".css"
            writers.push fs.outputFile uncriticalFile, hashed
            uncriticalFile = resolve(folder, hashed)
          writers.push fs.outputFile uncriticalFile, uncritical
          if item.compress or (not item.compress? and config.compress)
            try 
              zlib = require "node-zopfli"
            catch
              zlib = require "zlib"
            buf = new Buffer(uncritical)
            writers.push new Promise((resolve, reject) =>
              zlib.gzip buf, (err, result) =>
                return reject(err) if err
                resolve(result)
              ).then (result) => fs.outputFile uncriticalFile+".gz", result
            try 
              {compress} = require('iltorb')
              writers.push new Promise((resolve, reject) =>
                compress buf, (err, result) =>
                  return reject(err) if err
                  resolve(result)
                ).then (result) => fs.outputFile uncriticalFile+".br", result
          await Promise.all(writers)
    Promise.all(isDone)
    .then => chromeDone
  .then =>
  .catch (e) =>
    console.log(e)
    await Promise.all([
        chromeInstance?.kill()
        leaInstance?.close()
      ])
    return e