const path = require('path')
const yargs = require('yargs')
require('dotenv').config()
const bunyan = require('bunyan')
const BunyanFormat = require('bunyan-format')
const converter = require('./converter')

const log = bunyan.createLogger({
  name: 'node-typeset',
  level: process.env.LOG_LEVEL || 'info',
  stream: new BunyanFormat({ outputMode: process.env.LOG_FORMAT || 'short' })
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
  .option('batch-size', {
    alias: 'b',
    describe: 'Number of math elements to convert as a batch. Default: 3000'
  })
  .demandOption(['xhtml', 'output'])
  .help()
  .argv

const pathToInput = path.resolve(argv.xhtml)
const pathToCss = argv.css ? path.resolve(argv.css) : null
let outputFormat = 'html'
const batchSize = Number(argv.batchSize) || 3000

if (argv.batchSize && !String(argv.batchSize).match(/^[0-9]+$/)) {
  throw new Error('Invalid batch size. Batch size should be an integer.')
}

if (argv.format) {
  if (['svg', 'html'].indexOf(argv.format.toLowerCase()) >= 0) {
    outputFormat = argv.format.toLowerCase()
    log.debug(`Output format set to ${argv.format.toLowerCase()}`)
  } else {
    log.error('You provided wrong format. It will be set to default (html).')
  }
} else {
  log.warn('No output format. It will be set to default (html).')
}

if (!/\.xhtml$/.test(pathToInput)) {
  throw new Error('The input file must end with \'.xhtml\' so Chrome parses it as XML (strict) rather than HTML')
}

if (!/\.xhtml$/.test(argv.output)) {
  throw new Error('The output file should end with \'.xhtml\'')
}

log.debug(`Converting Math Using XHTML="${argv.xhtml}" and CSS="${argv.css}"`)
const highlightedPath = converter.highlightCodeElements(log, pathToInput.replace(/\\/g, '/'))
converter.createMapOfMathMLElements(log, highlightedPath, pathToCss, argv.output, outputFormat, batchSize)
  .then(exitStatus => process.exit(exitStatus))
  .catch(err => {
    log.fatal(err)
    process.exit(111)
  })
