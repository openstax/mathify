const path = require('path')
const yargs = require('yargs')
require('dotenv').config()
const bunyan = require('bunyan')
const BunyanFormat = require('bunyan-format')
const converter = require('./converter')

const log = bunyan.createLogger({
  name: 'node-typeset',
  level: process.env.LOG_LEVEL || 'info',
  stream: new BunyanFormat({outputMode: process.env.LOG_FORMAT || 'short'})
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
  .option('format', {
    alias: 'f',
    describe: 'Output format for MathJax Conversion: html, svg. Default: html'
  })
  .demandOption(['xhtml', 'output'])
  .help()
  .argv

const pathToInput = path.resolve(argv.xhtml)
const pathToCss = argv.css ? path.resolve(argv.css) : null
let outputFormat = 'html'

if (argv.format) {
  if (['svg', 'html'].indexOf(argv.format.toLowerCase()) >= 0) {
    outputFormat = argv.format.toLowerCase()
    log.debug(`Output format set to ${argv.format.toLowerCase()}`)
  } else {
    log.error(`You provided wrong format. It will be set to default (html).`)
  }
} else {
  log.warn(`No output format. It will be set to default (html).`)
}

log.debug(`Converting Math Using XHTML="${argv.xhtml}" and CSS="${argv.css}"`)
converter.createMapOfMathMLElements(log, pathToInput.replace(/\\/g, '/'), pathToCss, argv.output, outputFormat)
  .catch(err => {
    log.fatal(err)
    process.exit(111)
  })
