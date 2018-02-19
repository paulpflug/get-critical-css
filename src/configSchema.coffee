module.exports =
  delay:
    type: Number
    default: 200
    desc: "Wait after each navigation after frameStoppedLoading event for rendering"


  chromeFlags:
    type: Array
    default: [
      "--no-first-run"
      "--disable-translate"
      "--disable-background-networking"
      "--disable-extensions"
      "--disable-sync"
      "--metrics-recording-only"
      "--disable-default-apps"
      "--disable-gpu"
      "--headless"
    ]
    desc: "https://peter.sh/experiments/chromium-command-line-switches/"

  chromePort:
    type: Number
    default: 9222
    desc: "Chrome Debugging Protocol port to use"

  host:
    type: String
    _default: "localhost:8080"
    desc: "Where the website is hosted"

  profiles:
    type: Array
    default: [{
        width: 2560, height: 1440
      },{
        width: 1280, height: 1280
      },{
        width: 720, height: 1280, mobile: true
      },{
        width: 400, height: 800, mobile: true
      }]
    desc: "Device emulation: https://chromedevtools.github.io/devtools-protocol/tot/Emulation#method-setDeviceMetricsOverride"

  profiles$_item:
    type: Object
  
  profiles$_item$width:
    type: Number

  profiles$_item$height:
    type: Number

  profiles$_item$mobile:
    type: Boolean

  minify:
    type: [Boolean, Function]
    default: true
    _default: "Strip insignificant whitespace"
    desc: "Minify CSS"
  
  folder:
    type: String
    default: "./app_build"
    desc: "Output folder"

  files:
    type: Object
    strict: true
    default: {}

  files$critical:
    type: String
    default: "_critical"
    desc: "Filename used to write critical css"
  
  files$uncritical:
    type: String
    default: "_uncritical"
    desc: "Filename used to write uncritical css"

  hash:
    type: Boolean
    default: true
    desc: "Hash uncritical css"
  
  compress:
    type: Boolean
    default: true
    desc: "Compress uncritical css"
  
  startUp:
    type: Function
    desc: "Async function which should be used to start up the webserver"
  
  items:
    type: Array
    desc: "Generates a critical/uncritical pair for each $item"
  
  items$_item:
    types: [Object, Array, String]
    desc: "Options for one critical/uncritical pair"

  items$_item$routes:
    type: [Array, String]
    desc: "Routes that will be used, can be a shorthand for items.$item.routes.$item"

  items$_item$routes$_item:
    type: String
    desc: "Route to use. E.g. '/index' >> localhost:8080/index"

  items$_item$profiles:
    type: Array
    desc: "Overwrites default profiles option"

  items$_item$folder:
    type: String
    desc: "Overwrites default folder option"

  items$_item$files:
    type: Object
    strict: true

  items$_item$files$critical:
    type: String
    desc: "Overwrites default files.critical option"
  
  items$_item$files$uncritical:
    type: String
    desc: "Overwrites default files.uncritical option"

  items$_item$hash:
    type: Boolean
    desc: "Overwrites default hash option"
  
  items$_item$compress:
    type: Boolean
    desc: "Overwrites default compress option"
