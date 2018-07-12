const path = require('path')
const fs = require('fs')
const fileExists = require('file-exists')
const pify = require('pify')
const puppeteer = require('puppeteer')
const writeFile = pify(fs.writeFile)
const mjnodeConverter = require('./mjnode')

const PAGE_LOAD_TIME = 10 * 60 * 1000 // Wait 10 minutes before timing out (large books take a long time to open)
const PROGRESS_TIME = 10 * 1000 // 10 seconds

// Status codes
const STATUS_CODE = {
  OK: 0,
  ERROR: 111
}

const createMapOfMathMLElements = async (log, inputPath, cssPath, outputPath, outputFormat) => {
  let timeOfStart = new Date().getTime()
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
    timeout: PAGE_LOAD_TIME
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

  const mathEntries = await page.evaluate(/* istanbul ignore next */(PROGRESS_TIME) => {
    const mathNodes = document.getElementsByTagNameNS('http://www.w3.org/1998/Math/MathML', 'math')
    console.log(`Found ${mathNodes.length} MathML elements`)
    console.info('Extracting MathML elements from the document...')
    const total = mathNodes.length
    const mathMap/*: Map<string, string> */ = new Map()
    let prevTime = Date.now()
    let index = 0
    for (const mathNode of mathNodes) {
      const xml = mathNode.outerHTML
      // only set an ID if one does not already exist
      if (!mathNode.getAttribute('id')) {
        mathNode.setAttribute('id', `mjnode-${index}`)
        mathNode.classList.add('-remove-id-later')
      }

      const id = mathNode.getAttribute('id')

      // Print progress every 10 seconds
      const now = Date.now()
      if (now - prevTime > PROGRESS_TIME) {
        const percent = Math.floor(100 * index / total)
        console.info(`Extraction Progress: ${percent}%`)
        prevTime = now
      }
      if (mathMap.has(id)) {
        throw new Error(`Duplicate id detected: "${id}"`)
      }
      mathMap.set(id, xml)
      index++
    }
    return [...mathMap.entries()]
  }, PROGRESS_TIME)

  const convertedMathML/*: Map<string, {svg, html, css}> */ = await mjnodeConverter.convertMathML(log, new Map(mathEntries), outputFormat)

  log.info(`Inserting converted math elements...`)
  const mathSources = [...convertedMathML.entries()]
    .map(([id, {svg, html}]) => [id, svg || html])
  await page.evaluate(/* istanbul ignore next */(convertedMathMLEntries, PROGRESS_TIME) => {
    const total = convertedMathMLEntries.length
    let prevTime = Date.now()
    let index = 0
    for (const [id, xml] of convertedMathMLEntries) {
      const mathHTML = xml
      const mathNode = document.getElementById(id)
      if (!mathNode) {
        throw new Error(`BUG: Could not find element with id="${id}"`)
      }
      try {
        mathNode.outerHTML = mathHTML
      } catch (err) {
        console.error(`Problem inserting id="${id}" back into the document (might not be valid XML)`)
        console.error(mathHTML)
        mathNode.outerHTML = mathHTML
      }

      // Print progress every 10 seconds
      const now = Date.now()
      if (now - prevTime > PROGRESS_TIME) {
        const percent = Math.round(100 * index / total)
        console.info(`Inserted ${percent}% of all elements...`)
        prevTime = now
      }
      index++
    }
  }, mathSources, PROGRESS_TIME)

  // Inject any CSS that was generated by mathjax-node
  // The CSS content may be duplicated. If so, remove duplicates.
  const allCssMaybeDuplicate = [...convertedMathML.values()]
    .map(({css}) => css)
    .filter(css => !!css) // only keep the items that have a css block (this is null for svg)

  const allUniqueCss = new Set(allCssMaybeDuplicate)
  log.info(`Injecting MathJax-created CSS...`)
  await page.evaluate(/* istanbul ignore next */(allCss) => {
    console.info('Adding MathJax-created CSS')
    const head = document.querySelector('head')
    const style = document.createElement('style')
    style.innerHTML = allCss.join('\n')
    head.appendChild(style)
  }, [...allUniqueCss.values()])

  log.info(`Serializing XHTML back out...`)
  let convertedContent = await page.evaluate(/* istanbul ignore next */() => {
    console.log('Serializing content...')
    const s = new window.XMLSerializer()
    const convertedContent = s.serializeToString(document)
    return convertedContent
  })

  log.info('Saving file with injected math HTML elements...')
  log.debug(`Saving result to "${output}"`)
  await writeFile(output, convertedContent)
  log.info(`Content saved. Open "${output}" to see converted file.`)

  await browser.close()

  let timeOfEndInSec = (new Date().getTime() - timeOfStart) / 1000
  let timeOfEndInMin = timeOfEndInSec > 60 ? Math.round(timeOfEndInSec / 60) : 0
  let timeOfEnd = ''

  if (timeOfEndInMin) {
    timeOfEnd = `${timeOfEndInMin} minutes and ${timeOfEndInSec % 60} seconds.`
  } else {
    timeOfEnd = `${timeOfEndInSec} seconds.`
  }

  log.debug(`Script was running for: ${timeOfEnd}`)
  return STATUS_CODE.OK
}

module.exports = {
  createMapOfMathMLElements,
  STATUS_CODE
}
