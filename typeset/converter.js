const path = require('path')
const fileExists = require('file-exists')
const { XMLSerializer } = require('@xmldom/xmldom')
const { scanXML, looseTagEq } = require('./scan-xml')
const { PARAS } = require('./paras')
const sax = require('sax')

const fs = require('fs')
const mjnodeConverter = require('./mjnode')
const hljs = require('highlight.js')
const hljsLineNumbers = require('./hljs-line-numbers')
const { parseXML, ancestorOrSelf } = require('./dom-utils')

// Status codes
const STATUS_CODE = {
  OK: 0,
  ERROR: 111
}

const makeMathErrorHandler = (xmlPath, log) => (errorPairs) => {
  const xmlString = fs.readFileSync(xmlPath, { encoding: 'utf-8' })
  const xmlDoc = parseXML(xmlString, 'text/html')
  const elements = Object.values(xmlDoc.getElementsByTagName('*'))
  errorPairs.forEach(([err, match]) => {
    const matchInfo = { errors: err }
    const { attributes } = match.node
    let element
    // TODO: Ideally this would work for mathml elements too
    if ('data-math' in attributes) {
      const dataMath = attributes['data-math']
      element = elements.find((el) => el.getAttribute('data-math') === dataMath)
    }
    // If we found an element, walk up the tree and try to gather useful information
    if (element) {
      const targetAttributes = [
        'data-sm',
        'data-math',
        'data-injected-from-url',
        'data-injected-from-nickname',
        'data-injected-from-version'
      ]
      for (const el of ancestorOrSelf(element)) {
        targetAttributes.forEach((attrName) => {
          matchInfo[attrName] = matchInfo[attrName] || el.getAttribute(attrName)
        })
        if (matchInfo['data-sm']) break
      }
    }
    log.error(JSON.stringify(matchInfo, Object.keys(matchInfo).filter((k) => matchInfo[k]), 2))
  })
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
    { attr: 'data-math' }
  ]

  if (outputFormat === 'html') {
    matchers.push({ tag: 'head' })
  }

  // I fear what might happen if we try to convert from mathml to mathml
  if (outputFormat !== 'mathml') {
    log.debug('Adding matcher for mathml...')
    matchers.push({ tag: 'math' })
  }

  if (highlight) {
    log.debug('Adding matchers for code highlighting...')

    const tags = ['pre', 'code']
    const attributes = ['data-lang', 'lang']

    for (let i = 0; i < tags.length; i++) {
      for (let j = 0; j < attributes.length; j++) {
        matchers.push({ tag: tags[i], attr: attributes[j] })
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
          posEnd: match.posEnd,
          node: match.node
        }
        mathEntries.push(replacement)
        sortedReplacements.push(replacement)
      } else if (looseTagEq(match.node.name, 'head')) {
        /* istanbul ignore next */
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
  const handleErrors = makeMathErrorHandler(inputPath, log)
  for (let batch = 0; batch < Math.ceil(mathEntries.length / batchSize); batch++) {
    const start = batchSize * batch
    const end = Math.min(batchSize * batch + batchSize, mathEntries.length)
    log.info(`Converting math elements ${start} to ${end} of ${mathEntries.length}`)
    const uniqueCss = await mjnodeConverter.convertMathML(log, mathEntries.slice(start, end), outputFormat, mathEntries.length, start, handleErrors)
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
    /* istanbul ignore next */
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

function mergeAttributes (attributes, to) {
  Object.entries(attributes).forEach(([k, v]) => {
    let newValue = v
    const existingValue = to.getAttribute(k)
    if (
      existingValue != null &&
      existingValue.length > 0 &&
      newValue !== existingValue
    ) {
      /* istanbul ignore else */
      if (k === 'class') {
        newValue = [newValue, existingValue].join(' ')
      } else {
        // Class should be the only thing table is created with atm
        throw new Error(`Could not combine existing value for ${k}`)
      }
    }
    to.setAttribute(k, newValue)
  })
}

async function highlightCodeElements (codeEntries) {
  codeEntries.forEach(entry => {
    let el = parseXML(entry.element).documentElement
    // List of supported language classes: https://github.com/highlightjs/highlight.js/blob/master/SUPPORTED_LANGUAGES.md
    const language = getLanguage(el, 'data-lang') || getLanguage(el, 'lang')
    const hasLineNumbers = el.getAttribute('class').indexOf('line-numbering') !== -1
    const inputCode = el.textContent
    let outputHtml = hljs.highlight(language, inputCode).value
    if (hasLineNumbers) {
      outputHtml = hljsLineNumbers.addCodeLineNumbers(outputHtml)
      el = parseXML(outputHtml).documentElement
      mergeAttributes(entry.node.attributes, el)
    } else {
      const newNode = parseXML(`<tempElement xmlns="http://www.w3.org/1999/xhtml">${outputHtml}</tempElement>`).documentElement
      el.removeChild(el.firstChild)
      Array.from(newNode.childNodes).forEach(child => el.appendChild(child))
    }
    const localNamespaces = Object.keys(entry.node.attributes).filter(k => k.startsWith('xmlns'))
    entry.substitution = cleanNamespaces(el, localNamespaces)
  })
}

module.exports = {
  createMapOfMathMLElements,
  STATUS_CODE
}
