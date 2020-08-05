const path = require('path')
const {createHash} = require('crypto')
const fileExists = require('file-exists')
const puppeteer = require('puppeteer')
const fs = require('fs')
const pify = require('pify')
const readFile = pify(fs.readFile)
const writeFile = pify(fs.writeFile)
const mjnodeConverter = require('./mjnode')

const PAGE_LOAD_TIME = 10 * 60 * 1000 // Wait 10 minutes before timing out (large books take a long time to open)
const PROGRESS_TIME = 10 * 1000 // 10 seconds

// Status codes
const STATUS_CODE = {
  OK: 0,
  ERROR: 111
}

const mathNodePlaceholder = (id) => {
  return `<!-- math node ${id} -->`
}

const createMapOfMathMLElements = async (log, inputPath, cssPath, outputPath, outputFormat, batchSize) => {
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
    args: ['--no-sandbox', '--disable-dev-shm-usage'],
    devtools: process.env.BROWSER_DEBUGGER === 'true'
  })
  const page = await browser.newPage()

  // Disable resources, uses too much memory
  await page.setRequestInterception(true)
  page.on('request', (interceptedRequest) => {
    const url = interceptedRequest.url().split('#')[0].split('?')[0]
    if (url.startsWith('file:') && (url.endsWith('.xhtml') || url.endsWith('.html') || url.endsWith('.css'))) {
      return interceptedRequest.continue()
    }
    interceptedRequest.abort()
  })

  const browserLog = log.child({browser: 'console'})
  page.on('console', msg => {
    switch (msg.type()) {
      case 'error':
        // Loading an XHTML file with missing images is fine so we ignore
        // "Failed to load resource: net::ERR_FILE_NOT_FOUND" messages
        const text = msg.text()
        if (!text.match(/Failed to load resource: net::(ERR_FILE_NOT_FOUND|ERR_FAILED)/)) {
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

  const mathEntries = await page.evaluate((PROGRESS_TIME, PLACE_HOLDER_TEMPLATE) => {
    // No way to specify the namespace in css selectors, so namespace check is in the loop
    const mathNodes = document.querySelectorAll('*|math, [data-math]')
    console.info('Extracting MathML and LaTeX elements from the document...')
    let total = mathNodes.length
    const mathMap /* [{xml: string, fontSize: number}, ...] */ = []
    let prevTime = Date.now()
    let index = 0
    for (const mathNode of mathNodes) {
      // skip all the <math> nodes that are not in the MathML namespace
      if (mathNode.tagName === 'math' && mathNode.namespaceURI !== 'http://www.w3.org/1998/Math/MathML') {
        total -= 1
        continue
      }
      // Clean up the MathML
      [...mathNode.querySelectorAll('[mathvariant="bolditalic"]')].forEach(el => {
        console.warn(`ERROR: Found element with mathvariant="bolditalic". It should be "bold-italic". MathML=${mathNode.outerHTML}`)
        el.setAttribute('mathvariant', 'bold-italic')
      });
      [...mathNode.querySelectorAll('[mathvariant="italics"]')].forEach(el => {
        console.warn(`ERROR: Found element with mathvariant="italics". It should be "italic". MathML=${mathNode.outerHTML}`)
        el.setAttribute('mathvariant', 'italic')
      })

      const xml = mathNode.getAttribute('data-math') ? mathNode.getAttribute('data-math') : mathNode.outerHTML
      const fontSize = parseFloat(window.getComputedStyle(mathNode, null).getPropertyValue('font-size'))
      // put html comment placeholder for where the converted math should go
      mathNode.outerHTML = PLACE_HOLDER_TEMPLATE.replace('{id}', index)

      // Print progress every 10 seconds
      const now = Date.now()
      if (now - prevTime > PROGRESS_TIME) {
        const percent = Math.floor(100 * index / total)
        console.info(`Extraction Progress: ${percent}%`)
        prevTime = now
      }
      mathMap.push({xml, fontSize})
      index++
    }
    return mathMap
  }, PROGRESS_TIME, mathNodePlaceholder('{id}'))

  let pageContent = await page.evaluate(() => {
    const serializer = new window.XMLSerializer()
    return serializer.serializeToString(document.documentElement)
  })

  browser.close()

  let allUniqueCss = new Set()
  let nextMathNodeIndex
  for (let batch = 0; batch < Math.ceil(mathEntries.length / batchSize); batch++) {
    const start = batchSize * batch
    const end = Math.min(batchSize * batch + batchSize, mathEntries.length)
    log.info(`Converting math elements ${start} to ${end} of ${mathEntries.length}`)
    const [convertedMathML/*: Map<integer, {svg || html}> */, uniqueCss] = await mjnodeConverter.convertMathML(log, mathEntries.slice(start, end), outputFormat, mathEntries.length, start)
    allUniqueCss.add(uniqueCss)

    log.debug(`Inserting converted math elements...`)
    let convertedContent = []
    // sort the ids using numeric sort (default is string sort)
    for (const id of [...convertedMathML.keys()].sort((a, b) => a - b)) {
      const xml = convertedMathML.get(id)
      // Replacing placeholder with converted math
      nextMathNodeIndex = pageContent.indexOf(mathNodePlaceholder(id))
      if (nextMathNodeIndex === -1) {
        throw new Error(`Unable to find ${mathNodePlaceholder(id)}`)
      }
      convertedContent.push(pageContent.substr(0, nextMathNodeIndex))
      convertedContent.push(xml)
      pageContent = pageContent.substr(nextMathNodeIndex + mathNodePlaceholder(id).length)
    }
    await writeFile(output, convertedContent.join(''), {flag: batch === 0 ? 'w' : 'a'})
  }
  await writeFile(output, pageContent, {flag: 'a'})

  log.info(`Injecting MathJax-created CSS...`)
  pageContent = await readFile(output, 'utf-8')
  await writeFile(output, pageContent.replace('</head>', `<style>${[...allUniqueCss.keys()].join('\n')}</style></head>`, 1))

  log.info(`Content saved. Open "${output}" to see converted file.`)

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
