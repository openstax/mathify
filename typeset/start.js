const path = require('path')
const fs = require('fs')
const yargs = require('yargs')
require('dotenv').config()
const bunyan = require('bunyan')
const BunyanFormat = require('bunyan-format')
const converter = require('./converter')
const { createInterface } = require('readline')
const { walkJSON, MemoryWriteStream, MemoryReadStream, parseXML } = require('./helpers')
const { XMLSerializer } = require('@xmldom/xmldom')

const log = bunyan.createLogger({
  name: 'node-typeset',
  level: process.env.LOG_LEVEL || 'error',
  stream: new BunyanFormat({ outputMode: process.env.LOG_FORMAT || 'short' })
})

const argv = yargs
  .option('input', {
    alias: 'i',
    describe: 'Input File (xhtml, json, or \'-\' to read file list from stdin)'
  })
  .option('css', {
    alias: 'c',
    describe: 'Input CSS File'
  })
  .option('output', {
    alias: 'o',
    describe: 'Output XHTML File'
  })
  .option('highlight', {
    alias: 'h',
    default: false,
    describe: 'Enable insertion of code highlighting'
  })
  .option('format', {
    alias: 'f',
    describe: 'Output format for MathJax Conversion: html, svg. Default: html'
  })
  .option('batch-size', {
    alias: 'b',
    describe: 'Number of math elements to convert as a batch. Default: 3000'
  })
  .option('in-place', {
    alias: 'I',
    boolean: true,
    describe: 'Modify file(s) in-place'
  })
  .demandOption(['input'])
  .help()
  .argv

const pathToCss = argv.css ? path.resolve(argv.css) : null
let outputFormat = 'html'
const batchSize = Number(argv.batchSize) || 3000

if (argv.batchSize && !String(argv.batchSize).match(/^[0-9]+$/)) {
  throw new Error('Invalid batch size. Batch size should be an integer.')
}

if (argv.format) {
  if (['svg', 'html', 'mathml'].indexOf(argv.format.toLowerCase()) >= 0) {
    outputFormat = argv.format.toLowerCase()
    log.debug(`Output format set to ${argv.format.toLowerCase()}`)
  } else {
    log.error('You provided wrong format. It will be set to default (html).')
  }
} else {
  log.warn('No output format. It will be set to default (html).')
}

async function mathifyJSON (inputPath, outputPath, outputFormat) {
  const inputJSON = JSON.parse(fs.readFileSync(inputPath, { encoding: 'utf-8' }))
  const serializer = new XMLSerializer()
  log.info(inputPath)
  await walkJSON(inputJSON, async ({ parent, name, value, fqPath }) => {
    if (
      typeof value !== 'string' ||
      parent == null ||
      value.indexOf('math') === -1
    ) {
      return
    }
    const output = new MemoryWriteStream()
    const parseHTML = (html) => parseXML(html, {
      warn: (msg) => {
        log.warn(
          `${inputPath}:${name} - ${msg.replace(/\n/g, ' - ').replace(/\t/g, ' ')}`
        )
      },
      mimeType: 'text/html'
    })
    try {
      const el = parseHTML(
        `<tempElement xmlns="http://www.w3.org/1999/xhtml">${value}</tempElement>`
      ).documentElement
      const src = serializer.serializeToString(el)
      await converter.createMapOfMathMLElements(
        log,
        () => new MemoryReadStream(src),
        '',
        () => output,
        outputFormat,
        batchSize,
        false
      )
      const document = parseHTML(output.getValue())
      const parsed = document.documentElement
      for (const mathElement of Array.from(parsed.getElementsByTagName('math'))) {
        const semantics = document.createElement('semantics')
        const mrow = document.createElement('mrow')
        const annotation = document.createElement('annotation')
        for (const node of Array.from(mathElement.childNodes)) {
          mrow.appendChild(node)
        }
        annotation.setAttribute('encoding', 'LaTeX')
        annotation.textContent = mathElement.getAttribute('alttext')
        mathElement.removeAttribute('alttext')
        semantics.appendChild(mrow)
        semantics.appendChild(annotation)
        mathElement.appendChild(semantics)
      }
      const converted = serializer.serializeToString(parsed).slice(50, -14)
      Reflect.set(parent, name, converted)
    } catch (err) {
      log.error(`${inputPath}:${fqPath.join('.')} - ${err}`)
      process.exitCode = 111
    }
  })
  fs.writeFileSync(outputPath, JSON.stringify(inputJSON, null, 2))
}

async function runForFile (inputPathRaw, outputPathRaw, highlight, inPlace) {
  const inputPath = inputPathRaw.replace(/\\/g, '/')
  const outputPath = outputPathRaw != null && outputPathRaw.length === 0
    ? outputPathRaw.replace(/\\/g, '/')
    : `${inputPath}.mathified`
  if (inputPath.endsWith('.json')) {
    await mathifyJSON(inputPath, outputPath, outputFormat)
  } else if (inputPath.endsWith('.xhtml')) {
    const getInputStream = () => fs.createReadStream(inputPath)
    const getOutputStream = () => fs.createWriteStream(outputPath)

    await converter.createMapOfMathMLElements(
      log,
      getInputStream,
      pathToCss,
      getOutputStream,
      outputFormat,
      batchSize,
      highlight
    )
  } else {
    throw new Error('Expected XHTML or JSON file')
  }
  if (inPlace) {
    fs.renameSync(outputPath, inputPath)
  }
}

const promise = argv.input === '-'
  ? async () => {
    const readline = createInterface({ input: process.stdin })
    for await (const line of readline) {
      await runForFile(line, null, argv.highlight, argv.inPlace)
    }
  }
  : async () => await runForFile(argv.input, argv.output, argv.highlight, argv.inPlace)

promise().catch((err) => {
  log.fatal(err)
  process.exit(111)
})
