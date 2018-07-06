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
  const output = `${outputPath}`

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

  let res = await page.evaluate(/* istanbul ignore next */() => {
    let mathMLElements = document.getElementsByTagName('m:math')
    console.info(`Found ${mathMLElements.length} <m:math> elements`)
    console.info('Mapping mathML elements in the document...')
    console.log(`This loop will create object with "id: <m:math>" key vals and then replace all <m:math> elements with spans with proper ids.`)
    let mathMLElementsMap = {}
    let index = 0
    // Length of mathMLElements is decreasing with every loop,
    // because we are replacing <m:math> element with <span> after saving it in mathMLElementsMap
    // If you will try forEach loop on mathMLElements then it will process only half of elements
    // Array.isArray(mathMLElements) === false
    let fullLength = mathMLElements.length
    let progress = 0
    /* while(mathMLElements.length){
      mathMLElementsMap[index] = mathMLElements[mathMLElements.length - 1].outerHTML
      mathMLElements[mathMLElements.length - 1].outerHTML = `<span id="mjnode-${index}" class="mjnode-replace"></span>`
      let newProgress = Math.round((fullLength - mathMLElements.length) / fullLength * 100)
      if (Math.round(newProgress / 10) !== Math.round(progress / 10)){
        console.info(`Already mapped ${newProgress}% of all elements...`)
        progress = newProgress
      }
      index++
    } */
    /* Array.prototype.forEach.call(mathMLElements, (el, i) => {
      mathMLElementsMap[i] = el.outerHTML
      el.outerHTML = `<span id="mjnode-${i}" class="mjnode-replace"></span>`
      console.log(`mathMLElements.length: ${mathMLElements.length}`)
      console.log(`Switched ${i} element`)
    }) */
    for(let i = 0; i < mathMLElements.length; i++){
      mathMLElementsMap[i] = mathMLElements[i].outerHTML
      mathMLElements[i].id = `mjnode-${i}`
      let newProgress = Math.round((fullLength - mathMLElements.length) / fullLength * 100)
      if (Math.round(newProgress / 10) !== Math.round(progress / 10)){
        console.info(`Already mapped ${newProgress}% of all elements...`)
        progress = newProgress
      }
    }
    if(mathMLElements.length){
      console.error(`There is still ${mathMLElements.length} not converted mathML elements.`)
    }else{
      console.info('Mapped 100% of all elements.')
    }

    console.info('Starting serializing content...')
    let s = new window.XMLSerializer()
    let serializedContent = s.serializeToString(document)

    let res = {
      serializedContent: serializedContent,
      mathMLElementsMap: mathMLElementsMap
    }
    return res
  })

  log.info('Saving file without MathML elements...')
  await writeFile(output, res.serializedContent)

  log.info('Starting mjnodeConverter...')
  let convertedMathML = await mjnodeConverter.convertMathML(log, res.mathMLElementsMap)

  log.info(`Opening ${output}...`)
  await page.goto(`file://${path.resolve(output)}`)

  log.info(`Opened ${path.resolve(output)} file.`)

  log.info(`Starting inserting converted math elements...`)
  let convertedContent = await page.evaluate((convertedMathML) => {
    let fullLength = Object.keys(convertedMathML).length
    let progress = 0
    for(let i = 0; i < fullLength; i++){
      let mathHTML = convertedMathML[i]
      document.getElementById(`mjnode-${i}`).outerHTML = mathHTML
      let newProgress = Math.round((fullLength - (fullLength - i)) / fullLength * 100)
      if (Math.round(newProgress / 10) !== Math.round(progress / 10)){
          console.info(`Inserted ${newProgress}% of all elements...`)
          progress = newProgress
      }
    }
    
    console.info(`Inserted all ${fullLength} converted elements.`)
    return document.documentElement.innerHTML
  }, convertedMathML)

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
