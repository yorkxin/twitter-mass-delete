#!/usr/bin/env node

const path = require('path')

const filename = process.argv[2]

const basename = path.basename(filename, '.js')

global.window = { YTD: {} };
global.window.YTD[basename] = {}

require(filename)

global.window.YTD[basename].part0.forEach((data) => {
    console.log(JSON.stringify(data[basename]))
})

