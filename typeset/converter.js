const path = require('path')
const fileExists = require('file-exists')
const { DOMParser, XMLSerializer } = require('@xmldom/xmldom')
const { scanXML, looseTagEq } = require('./scan-xml')
const { PARAS } = require('./paras')
const sax = require('sax')

const fs = require('fs')
const mjnodeConverter = require('./mjnode')
const hljs = require('highlight.js')

// Status codes
const STATUS_CODE = {
  OK: 0,
  ERROR: 111
}

class ParseError extends Error { }

function parseXML (xmlString) {
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
  const doc = p.parseFromString(xmlString)
  return doc
}

const createMapOfMathMLElements = async (log, inputPath, cssPath, outputPath, outputFormat, batchSize, highlight) => {
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

  const parser = sax.parser(true)
  const output = path.resolve(outputPath)
  const mathEntries = []
  const codeEntries = []
  // Keep an array of all the replacements in the order they appeared in within the file
  const sortedReplacements = []
  let head

  log.info('Opening XHTML file (may take a few minutes)')
  log.debug(`Opening "${inputPath}"`)
  const inputContent = fs.createReadStream(inputPath).setEncoding('utf8')
  log.debug(`Opened "${inputPath}"`)

  const matchers = [
    { attr: 'data-math' },
    { tag: 'head' }
  ]

  // I fear what might happen if we try to convert from mathml to mathml
  if (outputFormat !== 'mathml') {
    log.debug('Adding matcher for mathml...')
    matchers.push({ tag: 'math' })
  }

  if (highlight) {
    log.debug('Adding matchers for code highlighting...')

    const tags = ['pre', 'code'];
    const attributes = ['data-lang', 'lang'];

    for (let i = 0; i < tags.length; i++) {
      for (let j = 0; j < attributes.length; j++) {
        matchers.push({ tag: tags[i], attr: attributes[j] });
      }
    }
  }

  scanXML(
    parser,
    matchers,
    match => {
      if (looseTagEq(match.node.name, 'math') || 'data-math' in match.node.attributes) {
        const replacement = {
          mathSource: 'data-math' in match.node.attributes
            ? match.node.attributes['data-math']
            : match.element,
          posStart: match.posStart,
          posEnd: match.posEnd
        }
        mathEntries.push(replacement)
        sortedReplacements.push(replacement)
      } else if (looseTagEq(match.node.name, 'head')) {
        if (head !== undefined) {
          throw new Error('Encountered two head elements')
        }
        head = match
        sortedReplacements.push(match)
      } else {
        codeEntries.push(match)
        sortedReplacements.push(match)
      }
    }
  )
  await new Promise((resolve, reject) => {
    parser.onerror = err => reject(err)
    inputContent.on('error', err => reject(err))
    inputContent.on('data', chunk => parser.write(chunk))
    inputContent.on('end', () => resolve())
  })
  log.debug(`Parsed "${inputPath}"`)

  // Prepare code highlighting
  await highlightCodeElements(codeEntries)

  const allUniqueCss = new Set()
  for (let batch = 0; batch < Math.ceil(mathEntries.length / batchSize); batch++) {
    const start = batchSize * batch
    const end = Math.min(batchSize * batch + batchSize, mathEntries.length)
    log.info(`Converting math elements ${start} to ${end} of ${mathEntries.length}`)
    const uniqueCss = await mjnodeConverter.convertMathML(log, mathEntries.slice(start, end), outputFormat, mathEntries.length, start)
    allUniqueCss.add(uniqueCss)
  }

  if (head !== undefined) {
    head.substitution = `${head.element.slice(0, -7)}<style><![CDATA[\n${[...allUniqueCss.keys()].join('\n')}\n]]></style></head>`
  }
  log.info('Updating content...')
  await new Promise((resolve, reject) => {
    const reader = fs.createReadStream(inputPath).setEncoding('utf8')
    const writer = fs.createWriteStream(outputPath)
    writer.on('error', err => reject(err))
    reader.on('error', err => reject(err))
    writer.on('finish', () => resolve())
    PARAS(sortedReplacements, reader, writer)
  })

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

function cleanNamespaces (el, keepNamespaces) {
  const serializer = new XMLSerializer()
  let serialized = serializer.serializeToString(el)
  Object.values(el.attributes)
    .filter(attr =>
      attr.name &&
      attr.name.startsWith('xmlns') &&
      keepNamespaces.indexOf(attr.name) === -1
    )
    .map(attr => ` ${attr.name}="${attr.value}"`)
    .forEach(nsDecl => { serialized = serialized.replace(nsDecl, '') })
  return serialized
}

function getLanguage (el, attr) {
  return el.getAttribute(attr).toLowerCase()
}

async function highlightCodeElements (codeEntries) {
  codeEntries.forEach(entry => {
    const el = parseXML(entry.element).documentElement
    // List of supported language classes: https://github.com/highlightjs/highlight.js/blob/master/SUPPORTED_LANGUAGES.md
    const language = getLanguage(el, 'data-lang') || getLanguage(el, 'lang')
    const inputCode = el.textContent
    const outputHtml = hljs.highlight(language, inputCode).value
    const newNode = parseXML(`<tempElement xmlns="http://www.w3.org/1999/xhtml">${outputHtml}</tempElement>`).documentElement
    const localNamespaces = Object.keys(entry.node.attributes).filter(k => k.startsWith('xmlns'))

    el.removeChild(el.firstChild)
    Array.from(newNode.childNodes).forEach(child => el.appendChild(child))
    entry.substitution = cleanNamespaces(el, localNamespaces)
  })
}

module.exports = {
  createMapOfMathMLElements,
  STATUS_CODE
}
