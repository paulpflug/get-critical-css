# get-critical-css
extracting inline critical css from html.

Uses chrome headless

### Install
```sh
npm install --save get-critical-css
```

### Usage
```js
getCriticalCss = require("get-critical-css")
// getCritical(options:Object)
{critical,uncritical} = getCritical({html: somehtml})
```

#### Options
Name | type | default | description
---:| --- | ---| ---
html | String | - | Provide html
stylesheets | String or Function | - | filter used stylesheets
chromeFlags | Array of Strings | ["--disable-gpu","--headless"] | flags to start chrome with
profiles | Array of Objects | 4 different display sizes | DeviceMetrics to use
delay | Number | 1000 | time after rendering to wait in ms 
timeout | Number | 10000 | timeout in ms
minify | Boolean | true | should not significant whitespace be omitted
save | String | - | Path where to save output
hash | Boolean | true | only with save - name of uncritical stylesheet is hashed
compress | Boolean | true | only with save - an additional compressed stylesheet is given out
criticalName | String | "_critical" | only with save - name of critical css file
uncriticalName | String | "_uncritical" | only with save - name of uncritical css file

Install `npm install node-zopfli` to use zopfli instead of `zlib` for compression.

## License
Copyright (c) 2017 Paul Pflugradt
Licensed under the MIT license.
