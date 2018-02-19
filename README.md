# get-critical-css

extract critical css from website(s)

## Features
- Configuration based
- Support for multiple bundles
- CLI
- Uses Chrome `takeCoverageDelta` which is very accurate
- Gets all your responsive CSS rules, by supporting different device profiles
- Post processes the CSS for you
- Works out of the box with `leajs` and `leajs-spa-router`


### Install
```sh
npm install --save get-critical-css
```

### Usage
```sh
# terminal
get-critical-css --help
# usage: get-critical-css (config file)

# config file is optional and defaults to "critical-css.config.[js|json|coffee|ts]"
# in "build/" and "/"

```

## critical-css.config
Read by [read-conf](https://github.com/paulpflug/read-conf), from `./` or `./build/` by default.
```js
// ./build/critical-css.config.js
module.exports = {

  // https://peter.sh/experiments/chromium-command-line-switches/
  // type: Array
  chromeFlags: ["--no-first-run","--disable-translate","--disable-background-networking","--disable-extensions","--disable-sync","--metrics-recording-only","--disable-default-apps","--disable-gpu","--headless"],

  // Chrome Debugging Protocol port to use
  chromePort: 9222, // Number

  // Compress uncritical css
  compress: true, // Boolean

  // Wait after each navigation after frameStoppedLoading event for rendering
  delay: 200, // Number

  // type: Object
  files: {

    // Filename used to write critical css
    critical: "_critical", // String

    // Filename used to write uncritical css
    uncritical: "_uncritical", // String

  },

  // Output folder
  folder: "./app_build", // String

  // Hash uncritical css
  hash: true, // Boolean

  // Where the website is hosted
  // Default: localhost:8080
  host: null, // String

  // Generates a critical/uncritical pair for each $item
  // $item ([Object, Array, String]) Options for one critical/uncritical pair
  // $item.routes ([Array, String]) Routes that will be used, can be a shorthand for items.$item.routes.$item
  // $item.routes.$item (String) Route to use. E.g. '/index' >> localhost:8080/index
  // $item.profiles (Array) Overwrites default profiles option
  // $item.folder (String) Overwrites default folder option
  // $item.files (Object)
  // $item.files.critical (String) Overwrites default files.critical option
  // $item.files.uncritical (String) Overwrites default files.uncritical option
  // $item.hash (Boolean) Overwrites default hash option
  // $item.compress (Boolean) Overwrites default compressoption
  items: null, // Array

  // Minify CSS
  // Default: Strip insignificant whitespace
  minify: null, // [Boolean, Function]

  // Device emulation: https://chromedevtools.github.io/devtools-protocol/tot/Emulation#method-setDeviceMetricsOverride
  // type: Array
  // $item (Object)
  // $item.width (Number)
  // $item.height (Number)
  // $item.mobile (Boolean)
  profiles: [{"width":2560,"height":1440},{"width":1280,"height":1280},{"width":720,"height":1280,"mobile":true},{"width":400,"height":800,"mobile":true}],

  // Async function which should be used to start up the webserver
  startUp: null, // Function

  // …

}
```

## Compress
`get-critical-css` compresses the uncritical css with Node `zlib` by default. 

You can also use `zopfli` and/or `brotli` compression by installing the corresponding packages:
```sh
npm install --save node-zopfli # to use zopfli instead of `zlib`
npm install --save iltorb # to additionally use brotli
```

## Hash
For cache invalidation the uncritical css is hashed by default.
Two files will be output:
- `${hash}.css` will contain the uncritical css
- `${files.uncritical}.css` will contain the hashed filename: `${hash}.css`

## How to use the generated files
The critical css should be inlined in your html file,
while the uncritical should be lazy linked, with a fallback for `noscript` environments.
There are several techniques get the generated CSS/files into your html, e.g. a template language like `pug.js`
```html
<head>
  …
  <style type='text/css'>${criticalCSS}</style>
  <noscript>
    <link rel='stylesheet' href='${uncriticalFile}'></link>
  </noscript>
  <script>
    window.addEventListener("load", function(){
      var l = document.createElement("link")
      l.type = "text/css"
      l.rel = "stylesheet"
      l.href = "${uncriticalFile}"
      document.head.appendChild(l)
    }, false)
  </script>
  …
</head>
```

## License
Copyright (c) 2017 Paul Pflugradt
Licensed under the MIT license.
