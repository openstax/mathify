const path = require('path')
const fs = require('fs')
const yargs = require('yargs')
const fileExists = require('file-exists')
require('dotenv').config()
const bunyan = require('bunyan')
const bunyanFormat = require('bunyan-format')
const mathJaxPath = require.resolve('mathjax/unpacked/MathJax')
const converter = require('./converter')

const log = bunyan.createLogger({
  name: 'node-typeset',
  level: process.env.LOG_LEVEL || 'info',
  stream: new bunyanFormat({outputMode: process.env.LOG_FORMAT || 'short'}),
})

const argv = yargs
  .option('xhtml', {
    alias: 'i',
    describe: 'Input XHTML File'
  })
  .option('css', {
    alias: 'c',
    describe: 'Input CSS File'
  })
  .option('output', {
    alias: 'o',
    describe: 'Output XHTML File'
  })
  .demandOption(['xhtml', 'output'])
  .help()
  .argv

const pathToInput = path.resolve(argv.xhtml)
const pathToCss = argv.css ? path.resolve(argv.css) : null
// Check that the XHTML and CSS files exist
if (!fileExists.sync(pathToInput)) {
  log.error(`Input XHTML file not found: "${pathToInput}"`)
  process.exit(111)
}
if (pathToCss && !fileExists.sync(pathToCss)) {
  log.error(`Input CSS file not found: "${pathToCss}"`)
  process.exit(111)
}

log.debug(`Converting Math Using XHTML="${argv.xhtml}" and CSS="${argv.css}"`)
converter.injectMathJax(log, pathToInput.replace(/\\/g, '/'), pathToCss, argv.output, mathJaxPath)
