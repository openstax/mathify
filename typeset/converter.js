const path = require('path')
const fs = require('fs')
const {createHash} = require('crypto')
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

  const browserLog = log.child({browser: 'console'})
  page.on('console', msg => {
    switch (msg.type()) {
      case 'error':
        // Loading an XHTML file with missing images is fine so we ignore
        // "Failed to load resource: net::ERR_FILE_NOT_FOUND" messages
        const text = msg.text()
        if (text !== 'Failed to load resource: net::ERR_FILE_NOT_FOUND') {
          browserLog.error(msg.text())
        }
        break
      case 'warning':
        browserLog.warn(msg.text())
        break
      case 'info':
        browserLog.info(msg.text())
        break
      case 'log':
        browserLog.debug(msg.text())
        break
      default:
        browserLog.error(msg.type(), msg.text())
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

  // Collect code coverage of the browser JS
  await injectCoverageCollection(page)

  await page.evaluate(() => {
    window.__TYPESET_CONFIG = {
      isDone: false,
      isFailed: false,
      elementsToRemove: [],
      isDoneSwitching: false
    }
  })

  if (cssPath) {
    log.info(`Injecting CSS...`)
    await page.mainFrame().addStyleTag({
      path: cssPath
    })
  }

  const mathEntries = await page.evaluate((PROGRESS_TIME) => {
    const mathNodes = document.getElementsByTagNameNS('http://www.w3.org/1998/Math/MathML', 'math')
    console.log(`Found ${mathNodes.length} MathML elements`)
    console.info('Extracting MathML elements from the document...')
    const total = mathNodes.length
    const mathMap/*: Map<string, {xml: string, fontSize: number}> */ = new Map()
    let prevTime = Date.now()
    let index = 0
    for (const mathNode of mathNodes) {
      const xml = mathNode.outerHTML
      const fontSize = parseFloat(window.getComputedStyle(mathNode.parentElement, null).getPropertyValue('font-size'))
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
      mathMap.set(id, {xml, fontSize})
      index++
    }
    return [...mathMap.entries()]
  }, PROGRESS_TIME)

  const convertedMathML/*: Map<string, {svg, html, css}> */ = await mjnodeConverter.convertMathML(log, new Map(mathEntries), outputFormat)

  log.info(`Inserting converted math elements...`)
  const mathSources = [...convertedMathML.entries()]
    .map(([id, {svg, html}]) => [id, svg || html])
  await page.evaluate((convertedMathMLEntries, PROGRESS_TIME) => {
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
  await page.evaluate((allCss) => {
    console.info('Adding MathJax-created CSS')
    const head = document.querySelector('head')
    const style = document.createElement('style')
    style.innerHTML = allCss.join('\n')
    head.appendChild(style)
  }, [...allUniqueCss.values()])

  log.info(`Serializing XHTML back out...`)
  let convertedContent = await page.evaluate(() => {
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

async function injectCoverageCollection (page) {
  // From https://github.com/GoogleChrome/puppeteer/pull/1067/files
  if (global.__coverage__) {
    const coverageObjects = {}
    Object.keys(global.__coverage__).forEach(filename => {
      // The variable name of the coverage object is a hash of the filename
      // Istanbul computes this so we need to compute it as well.
      const hash = createHash('sha1')
      hash.update(filename)
      const key = parseInt(hash.digest('hex').substr(0, 12), 16).toString(36)
      coverageObjects[key] = global.__coverage__[filename]
    })
    await page.exposeFunction('cv_proxy_add', /* istanbul ignore next */ async arr => {
      arr = JSON.parse(arr)
      let obj = coverageObjects
      while (arr.length > 1) { obj = obj[arr.shift()] }
      obj[arr.shift()]++
    })
    await page.evaluate(/* istanbul ignore next */ keys => {
      const createProxy = parents => {
        parents = parents.slice()
        return new Proxy({}, {
          get: (target, name) => 0,
          set: (obj, prop, value) => {
            const arr = parents.concat([prop])
            window.cv_proxy_add(JSON.stringify(arr))
            return true
          }
        })
      }
      keys.forEach(key => {
        window[`cov_${key}`] = {
          f: createProxy([key, 'f']),
          s: createProxy([key, 's']),
          b: createProxy([key, 'b'])
        }
      })
    }, Object.keys(coverageObjects))
  }
}

module.exports = {
  createMapOfMathMLElements,
  STATUS_CODE
}
