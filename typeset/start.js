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
  level: process.env.LOG_LEVEL || 'warn',
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


if (argv.input === '-') {
  const readline = createInterface({ input: process.stdin })
  const inner = async () => {
    for await (const line of readline) {
      if (line.endsWith('.json')) {
        const inputJSON = JSON.parse(fs.readFileSync(line, { encoding: 'utf-8' }))
        log.info(line)
        await walkJSON(inputJSON, async ({ parent, name, value }) => {
          if (
            typeof value !== 'string' ||
            parent == null ||
            value.indexOf("data-math") === -1
          ) return
          const output = new MemoryWriteStream()
          const serializer = new XMLSerializer()
          const el = parseXML(
            `<tempElement xmlns="http://www.w3.org/1999/xhtml">${value}</tempElement>`,
            (msg) => log.warn(`${line}:${name} - ${msg.replace(/\n/g, " - ").replace(/\t/g, ' ')}`)
          ).documentElement
          const src = serializer.serializeToString(el)
          try {
            await converter.createMapOfMathMLElements(
              log,
              () => new MemoryReadStream(src),
              pathToCss,
              () => output,
              outputFormat,
              batchSize,
              argv.highlight
            )
            let converted = output.getValue()
            // const parsed = parseXML(converted, log).documentElement
            // for (const mathElement of Array.from(parsed.getElementsByTagName('math'))) {
            //   const semantics = parseXML(`<semantics></semantics>`).documentElement
            //   const annotation = parseXML(`<annotation encoding="LaTeX">${mathElement.getAttribute("alttext")}</annotation>`)
            //   for (const node of Array.from(mathElement.childNodes)) {
            //     semantics.appendChild(node)
            //   }
            //   semantics.appendChild(annotation)
            //   mathElement.appendChild(semantics)
            // }
            // converted = serializer.serializeToString(parsed);
            converted = converted.slice(50, -14)
            Reflect.set(parent, name, converted)
          } catch (err) {
            log.error(`${line}:${name} - ${err}`)
          }
        })
        fs.writeFileSync(`${line}.mathified`, JSON.stringify(inputJSON, null, 2))
        fs.renameSync(`${line}.mathified`, line)
      }
    }
  }
  inner().catch((err) => {
    log.fatal(err)
    process.exit(111)
  })
}

// async function runForFile(getInputStream, getOutputStream, highlight) {
//   const inputPath = input.replace(/\\/g, '/')
//   const getInputStream = () => fs.createReadStream(inputPath)
//   const getOutputStream = () => fs.createWriteStream(output)
//   if (!/\.(xhtml|json)$/.test(input)) {
//     throw new Error('The input file must end with \'.xhtml\' so Chrome parses it as XML (strict) rather than HTML')
//   }
//   log.debug(`Converting Math Using "${input}"`)
//   await converter.createMapOfMathMLElements(
//     log,
//     getInputStream,
//     pathToCss,
//     getOutputStream,
//     outputFormat,
//     batchSize,
//     highlight
//   )
// }
