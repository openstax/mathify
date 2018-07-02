const fs = require('fs')
const fileExists = require('file-exists')
const pify = require('pify')
const puppeteer = require('puppeteer')
const writeFile = pify(fs.writeFile)

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

const injectMathJax = async (log, inputPath, cssPath, outputPath, mathJaxPath) => {
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
      elementsToRemove: []
    }
  })

  log.debug(`Injecting CSS...`)
  await page.evaluate(/* istanbul ignore next */stylePath => {
    if (stylePath) {
      console.log('Setting stylesheets...')
      const style = document.createElement('link')
      style.rel = 'stylesheet'
      style.href = stylePath
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

  // Typeset equations
  log.info(`Injecting MathJax (and typesetting)...`)
  const didMathJaxLoad = await page.evaluate(/* istanbul ignore next */(mathJaxPath) => {
    console.log('Setting config for MathJax...')
    const MATHJAX_CONFIG = {
      extensions: ['mml2jax.js', 'MatchWebFonts.js'],
      jax: ['input/MathML', 'output/HTML-CSS'],
      showMathMenu: false,
      showMathMenuMSIE: false,
      mml2jax: {
        preview: 'none'
      },
      'AssistiveMML': {
        // AssistiveMML inserts additional MathML into the page, which
        // prince then rejects.
        disabled: true
      },
      MatchWebFonts: {
        matchFor: {
          CommonHTML: true,
          'HTML-CSS': true,
          SVG: true
        },
        fontCheckDelay: 2000,
        fontCheckTimeout: 30 * 1000
      },
      CommonHTML: {
        linebreaks: {
          automatic: true
        },
        scale: 100 / 1.27,
        minScaleAdjust: 75
        // mtextFontInherit: true,
      },
      'HTML-CSS': {
        preferredFont: 'STIX-Web',
        imageFont: null,
        // mtextFontInherit: true,
        noReflows: false
      },
      SVG: {
        font: 'STIX-Web'
        // mtextFontInherit: true,
      }
    }

    // Wait until the script has loaded and then return if it was successful or not
    return new Promise((resolve, reject) => {
      function typeset () {
        console.log('Begin typesetting...')
        window.MathJax.Hub.Queue(function () {
          document.querySelector('body>:first-child').style.setProperty('display', 'none')
          window.__TYPESET_CONFIG.isDone = true
        })
        window.MathJax.Hub.setRenderer('HTML-CSS')
        window.MathJax.Hub.Config(MATHJAX_CONFIG)
        resolve(true)
      };

      const mjax = document.createElement('script')
      mjax.addEventListener('load', typeset)
      mjax.addEventListener('error', function (ev) {
        window.__TYPESET_CONFIG.isFailed = true
        console.error('Unable to load MathJax. NOTE: MathJax needs to be in the same directory (or a child) of the XHTML file')
        reject(new Error('Unable to load MathJax.'))
      })
      console.log(`Attempting to inject MathJax from "${mathJaxPath}"`)
      mjax.src = mathJaxPath
      document.body.appendChild(mjax)
    })
  }, mathJaxPath)

  if (!didMathJaxLoad) {
    log.fatal('MathJax did not load')
    return STATUS_CODE.ERROR
  }
  await sleep(1000) // wait for MathJax to load

  log.info(`Polling to see when MathJax is done typesetting...`)
  let pageContentAfterSerialize = ''
  while (true) {
    const {isFailed, isDone} = await page.evaluate(/* istanbul ignore next */() => {
      if (!window.MathJax) {
        console.error('MathJax was not loaded')
        return {isFailed: true}
      }
      let msg = document.getElementById('MathJax_Message')
      if (msg && msg.innerText !== '') {
        console.info(`Progress: "${document.getElementById('MathJax_Message').innerText}"`)
      }
      return {
        isDone: window.__TYPESET_CONFIG.isDone,
        isFailed: window.__TYPESET_CONFIG.isFailed
      }
    })
    if (isFailed) {
      log.fatal('Failed for some reason. Check logs')
      await browser.close()
      return STATUS_CODE.ERROR
    } else if (isDone) {
      log.info('Serializing document...')
      pageContentAfterSerialize = await page.evaluate(/* istanbul ignore next */() => {
        // Remove any elements we added
        window.__TYPESET_CONFIG.elementsToRemove.forEach(el => el.remove())

        let s = new window.XMLSerializer()
        let str = s.serializeToString(document)
        if (window.MathJax && window.MathJax.Message) {
          console.log('All messages from MathJax:', JSON.stringify(window.MathJax.Message.Log()))
        } else {
          console.error('Could not find window.MathJax.Message')
        }
        return str
      })
      break
    }

    // Wait a second before polling again
    await sleep(1000)
  }

  log.info('Saving file...')
  await writeFile(output, pageContentAfterSerialize)
  log.info(`Content saved. Open "${output}" to see converted file.`)

  await browser.close()

  return STATUS_CODE.OK
}

module.exports = {
  injectMathJax,
  STATUS_CODE
}
