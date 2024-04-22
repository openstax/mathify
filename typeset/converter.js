const { XMLSerializer } = require('@xmldom/xmldom')
const { scanXML, looseTagEq } = require('./scan-xml')
const { PARAS } = require('./paras')
const sax = require('sax')

const mjnodeConverter = require('./mjnode')
const hljs = require('highlight.js')
const hljsLineNumbers = require('./hljs-line-numbers')
const { parseXML } = require('./helpers')

// Status codes
const STATUS_CODE = {
  OK: 0,
  ERROR: 111
}

const createMapOfMathMLElements = async (log, getInputStream, cssPath, getOutputStream, outputFormat, batchSize, highlight) => {
  const timeOfStart = new Date().getTime()

  const parser = sax.parser(true)
  const mathEntries = []
  const codeEntries = []
  // Keep an array of all the replacements in the order they appeared in within the file
  const sortedReplacements = []
  let head

  const inputContent = getInputStream().setEncoding('utf8')

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
      } else if (looseTagEq(match.node.name, 'pre') || looseTagEq(match.node.name, 'code')) {
        codeEntries.push(match)
        sortedReplacements.push(match)
      } else {
        const attr = JSON.stringify(match.node.attributes)
        throw new Error(`Got unexpected node: ${match.node.name} ${attr}`)
      }
    }
  )
  await new Promise((resolve, reject) => {
    parser.onerror = err => reject(err)
    inputContent.on('error', err => reject(err))
    inputContent.on('data', chunk => parser.write(chunk))
    inputContent.on('end', () => resolve())
  })

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
    const reader = getInputStream().setEncoding('utf8')
    const writer = getOutputStream()
    writer.on('error', err => reject(err))
    reader.on('error', err => reject(err))
    writer.on('finish', () => resolve())
    PARAS(sortedReplacements, reader, writer)
  })

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
    const hasLineNumbers = el.getAttribute('class').indexOf('line-numbering') !== -1
    const inputCode = el.textContent
    let outputHtml = hljs.highlight(language, inputCode).value
    if (hasLineNumbers) {
      outputHtml = hljsLineNumbers.addCodeLineNumbers(outputHtml)
    }
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
