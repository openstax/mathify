const path = require('path')
const fileExists = require('file-exists')
const { DOMParser, XMLSerializer } = require('xmldom')
const { useNamespaces } = require('xpath-ts')

const fs = require('fs')
const pify = require('pify')
const writeFile = pify(fs.writeFile)
const mjnodeConverter = require('./mjnode')
const hljs = require('highlight.js')

// Status codes
const STATUS_CODE = {
  OK: 0,
  ERROR: 111
}

const serializer = new XMLSerializer()
const select = useNamespaces({ mml: 'http://www.w3.org/1998/Math/MathML', h: 'http://www.w3.org/1999/xhtml' })

class ParseError extends Error { }

// Add the source filename to every node (not just the line/column)
function recAddFilenameToNodes (n, filename) {
  n.filename = filename
  for (const c of Array.from(n.childNodes || [])) {
    recAddFilenameToNodes(c, filename)
  }
  const attrs = n.attributes
  for (const attr of Array.from(attrs || [])) {
    attr.filename = filename
  }
}
function parseXML (fileContent, filename) {
  const locator = { lineNumber: 0, columnNumber: 0 }
  const cb = () => {
    const pos = {
      line: locator.lineNumber - 1,
      character: locator.columnNumber - 1
    }
    throw new ParseError(`ParseError: ${JSON.stringify(pos)}`)
  }
  const p = new DOMParser({
    locator,
    errorHandler: {
      warning: console.warn,
      error: cb,
      fatalError: cb
    }
  })
  const doc = p.parseFromString(fileContent)
  recAddFilenameToNodes(doc.documentElement, filename)
  return doc
}

const createMapOfMathMLElements = async (log, inputPath, cssPath, outputPath, outputFormat, batchSize) => {
  const timeOfStart = new Date().getTime()

  // Check that the XHTML and CSS files exist
  if (!fileExists.sync(inputPath)) {
    log.error(`Input XHTML file not found: "${inputPath}"`)
    return STATUS_CODE.ERROR
  }
  if (cssPath && !fileExists.sync(cssPath)) {
    log.error(`Input CSS file not found: "${cssPath}"`)
    return STATUS_CODE.ERROR
  }

  const output = path.resolve(outputPath)

  log.info('Opening XHTML file (may take a few minutes)')
  log.debug(`Opening "${inputPath}"`)
  const inputContent = fs.readFileSync(inputPath, 'utf-8')
  log.debug(`Opened "${inputPath}"`)
  const xmlRoot = parseXML(inputContent)
  log.debug(`Parsed "${inputPath}"`)

  // Inject code highlighting
  await highlightCodeElements(xmlRoot)

  /* mathEntries: Array<{ el, mathSource }> */
  const mmlEntries = select('//mml:math', xmlRoot).map(el => ({ el, mathSource: serializer.serializeToString(el) }))
  const texEntries = select('//*[@data-math]', xmlRoot).map(el => ({ el, mathSource: el.getAttribute('data-math') }))
  const mathEntries = [...mmlEntries, ...texEntries]

  const allUniqueCss = new Set()
  for (let batch = 0; batch < Math.ceil(mathEntries.length / batchSize); batch++) {
    const start = batchSize * batch
    const end = Math.min(batchSize * batch + batchSize, mathEntries.length)
    log.info(`Converting math elements ${start} to ${end} of ${mathEntries.length}`)
    const [convertedMathML/*: Map<Element, {svg || html}> */, uniqueCss] = await mjnodeConverter.convertMathML(log, mathEntries.slice(start, end), outputFormat, mathEntries.length, start)
    allUniqueCss.add(uniqueCss)

    log.debug('Inserting converted math elements...')
    // sort the ids using numeric sort (default is string sort)
    for (const el of convertedMathML.keys()) {
      const xmlStr = convertedMathML.get(el)
      const convertedNode = parseXML(xmlStr)
      el.parentNode.replaceChild(convertedNode, el)
    }
  }
  const pageContent = serializer.serializeToString(xmlRoot)

  log.info('Injecting MathJax-created CSS...')
  await writeFile(output, pageContent.replace('</head>', `<style><![CDATA[\n${[...allUniqueCss.keys()].join('\n')}\n]]></style></head>`, 1))

  log.info(`Content saved. Open "${output}" to see converted file.`)

  const timeOfEndInSec = (new Date().getTime() - timeOfStart) / 1000
  const timeOfEndInMin = timeOfEndInSec > 60 ? Math.round(timeOfEndInSec / 60) : 0
  let timeOfEnd = ''

  if (timeOfEndInMin) {
    timeOfEnd = `${timeOfEndInMin} minutes and ${timeOfEndInSec % 60} seconds.`
  } else {
    timeOfEnd = `${timeOfEndInSec} seconds.`
  }

  log.debug(`Script was running for: ${timeOfEnd}`)
  return STATUS_CODE.OK
}

async function highlightCodeElements (xmlRoot) {
  select('//h:pre[@data-lang]', xmlRoot).forEach(el => {
    // List of supported language classes: https://github.com/highlightjs/highlight.js/blob/master/SUPPORTED_LANGUAGES.md
    const language = el.getAttribute('data-lang').toLowerCase()
    const inputCode = el.textContent
    const outputHtml = hljs.highlight(language, inputCode).value
    const newNode = parseXML(`<tempElement xmlns="http://www.w3.org/1999/xhtml">${outputHtml}</tempElement>`)
    // el.parentNode.replaceChild(newNode, el)

    el.removeChild(el.firstChild)
    Array.from(newNode.childNodes).forEach(child => el.appendChild(child))
  })
}

module.exports = {
  createMapOfMathMLElements,
  STATUS_CODE
}
