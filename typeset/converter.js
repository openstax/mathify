const path = require('path')
const fs = require('fs')
const fileExists = require('file-exists')
const pify = require('pify')
const puppeteer = require('puppeteer')
const writeFile = pify(fs.writeFile)
const mjnodeConverter = require('./mjnode')

// Helper so we can write `await sleep(1000)`
async function sleep (ms) {
  return new Promise((resolve) => {
      setTimeout(resolve, ms)
  })
}

// Status codes
const STATUS_CODE = {
  OK: 0,
  ERROR: 111
}

const createMapOfMathMLElements = async (log, inputPath, cssPath, outputPath) => {
  // Check that the XHTML and CSS files exist
  if (!fileExists.sync(inputPath)) {
    log.error(`Input XHTML file not found: "${inputPath}"`)
    return STATUS_CODE.ERROR
  }
  if (cssPath && !fileExists.sync(cssPath)) {
    log.error(`Input CSS file not found: "${cssPath}"`)
    return STATUS_CODE.ERROR
  }

  const url = `file://${inputPath}`
  const output = path.resolve(outputPath)

  log.debug('Starting puppeteer...')
  const browser = await puppeteer.launch({
    args: ['--no-sandbox'],
    devtools: process.env.BROWSER_DEBUGGER === 'true'
  })
  const page = await browser.newPage()

  page.on('console', msg => {
    switch (msg.type()) {
      case 'error':
        // Loading an XHTML file with missing images is fine so we ignore
        // "Failed to load resource: net::ERR_FILE_NOT_FOUND" messages
        const text = msg.text()
        if (text !== 'Failed to load resource: net::ERR_FILE_NOT_FOUND') {
          log.error('browser-console', msg.text())
        }
        break
      case 'warning':
        log.warn('browser-console', msg.text())
        break
      case 'info':
        log.info('browser-console', msg.text())
        break
      case 'log':
        log.debug('browser-console', msg.text())
        break
      default:
        log.error('browser-console', msg.type(), msg.text())
        break
    }
  })
  page.on('pageerror', msgText => {
    log.fatal('browser-ERROR', msgText)
    return STATUS_CODE.ERROR
  })

  log.info(`Opening XHTML file (may take a few minutes)`)
  log.debug(`Opening "${url}"`)
  await page.goto(url, {
    timeout: 10 * 60 * 1000 // Wait 10 minutes before timing out (large books take a long time to open)
  })
  log.debug(`Opened "${url}"`)

  await page.evaluate(/* istanbul ignore next */() => {
    window.__TYPESET_CONFIG = {
      isDone: false,
      isFailed: false,
      elementsToRemove: [],
      isDoneSwitching: false
    }
  })

  log.debug(`Injecting CSS...`)
  await page.evaluate(/* istanbul ignore next */cssPath => {
    if (cssPath) {
      console.log('Setting stylesheets...')
      const style = document.createElement('link')
      style.rel = 'stylesheet'
      style.href = cssPath
      document.body.appendChild(style)
      window.__TYPESET_CONFIG.elementsToRemove.push(style)
    } else {
      console.warn('No CSS file provided')
    }

    console.log('Setting metadata...')
    if (!document.head) {
      const head = document.createElement('head')
      document.documentElement.insertBefore(head, document.body)
    }
    const meta = document.createElement('meta')
    meta.setAttribute('charset', 'utf-8')
    document.head.appendChild(meta)
    window.__TYPESET_CONFIG.elementsToRemove.push(meta)
  }, cssPath)

  const {serializedContent, mathEntries} = await page.evaluate(/* istanbul ignore next */() => {
    const mathNodes = document.getElementsByTagName('m:math')
    console.log(`Found ${mathNodes.length} <m:math> elements`)
    console.info('Extracting MathML elements from the document...')
    const total = mathNodes.length
    const mathMap/*: Map<string, string>*/ = new Map()
    let prevPercent = 0
    let index = 0
    for (const mathNode of mathNodes) {
      const percent = Math.floor(100 * index / total)
      const xml = mathNode.outerHTML
      // only set an ID if one does not already exist
      if (!mathNode.getAttribute('id')) {
        mathNode.setAttribute('id', `mjnode-${index}`)
        mathNode.classList.add('-remove-id-later')
      }

      const id = mathNode.getAttribute('id')
      if (percent % 10 === 0 && total > 100 && prevPercent !== percent) {
        console.info(`Extraction Progress ${percent}%`)
      }
      if (mathMap.has(id)) {
        throw new Error(`Duplicate id detected: "${id}"`)
      }
      mathMap.set(id, xml)
      index++
      prevPercent = percent
    }
    console.info('Serializing temporary content...')
    const s = new window.XMLSerializer()
    const serializedContent = s.serializeToString(document)

    return {
      serializedContent: serializedContent,
      mathEntries: [...mathMap.entries()]
    }
  })

  const convertedMathML = await mjnodeConverter.convertMathML(log, new Map(mathEntries))

  log.debug(`Opened ${output} file.`)
  log.info(`Inserting converted math elements...`)
  let convertedContent = await page.evaluate(/* istanbul ignore next */(convertedMathMLEntries) => {
    const convertedMathML = new Map(convertedMathMLEntries)
    let fullLength = convertedMathML.size
    let prevPercent = 0
    let index = 0
    for(const [id, xml] of convertedMathML.entries()){
      const percent = Math.round(100 * index / total)
      const mathHTML = xml
      const mathNode = document.getElementById(id)
      if (!mathNode) {
        throw new Error(`BUG: Could not find element with id="${id}"`)
      }
      mathNode.outerHTML = mathHTML
      if (prevPercent !== percent && percent % 10 === 0){
          console.info(`Inserted ${percent}% of all elements...`)
          prevPercent = percent
      }
      index++
    }

    console.log(`Inserted ${fullLength} elements`)
    console.info('Serializing content...')
    const s = new window.XMLSerializer()
    const convertedContent = s.serializeToString(document)
    return convertedContent

  }, [...convertedMathML.entries()])

  log.info('Saving file with injected math HTML elements...')
  await writeFile(output, convertedContent)
  log.info(`Content saved. Open "${output}" to see converted file.`)

  await browser.close()

  return STATUS_CODE.OK
}

module.exports = {
  createMapOfMathMLElements,
  STATUS_CODE
}
