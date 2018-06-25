const path = require('path')
const fs = require('fs')
const pify = require('pify')
const puppeteer = require('puppeteer')
const writeFile = pify(fs.writeFile)
require('dotenv').config()
const bunyan = require('bunyan')
let level = process.env.LOG_LEVEL || 'info'
let log = bunyan.createLogger({
  name: 'typeset converter',
  streams: [
    {
      level: level,
      stream: process.stdout
    },
    {
      type: 'rotating-file',
      path: path.join(__dirname, `/logs/log-typeset-converter-${Date.now()}.log`),
      period: '1d',
      count: 30
    }
  ]
})

const injectMathJax = async (inputPath, cssPath, outputPath, dirname) => {
  function clearTerminal () {
    if (process.platform === 'darwin') {
      process.stdout.write('\x1Bc')
    } else if (process.platform === 'win32') {
      process.stdout.write('\x1Bc')
    }
  }

  const url = `file://${inputPath}`
  const stylemj = `${cssPath}`
  const output = `${outputPath}`

  log.info('Starting puppeteer...')
  const browser = await puppeteer.launch({args: ['--no-sandbox']})
  const page = await browser.newPage()

  page.on('console', msg => {
    log.info('PAGE LOG:', msg.text())
  })
  page.on('pageerror', msg => {
    log.error('PAGE LOG ERROR:', msg.text())
  })

  await page.goto(url)

  await page.evaluate(function () {
    window.__c = {
      done: false,
      status: 0
    }

    console.log('Removing non-breaking spaces...')
    let b = document.body
    let withoutSpaces = b.innerHTML.replace(/&nbsp;/g, ' ')
    b = withoutSpaces
  })

  // Insert stylesheet

  await page.evaluate(style => {
    const c = window.__c

    console.log('Setting stylesheets...')
    c.style = document.createElement('link')
    c.style.rel = 'stylesheet'
    c.style.href = style
    document.body.appendChild(c.style)

    console.log('Setting metadata...')
    const meta = document.createElement('meta')
    meta.setAttribute('charset', 'utf-8')
    document.head.appendChild(meta)
  }, stylemj)

  // Typeset equations
  await page.evaluate((dirname) => {
    const c = window.__c

    console.log('Setting config for MathJax...')
    const CONFIG = {
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

    function typeset () {
      window.MathJax.Hub.Queue(function () {
        document.querySelector('body>:first-child').style.setProperty('display', 'none')
        c.done = true
      })
      window.MathJax.Hub.setRenderer('HTML-CSS')
      window.MathJax.Hub.Config(CONFIG)
    };

    c.mjax = document.createElement('script')
    c.mjax.addEventListener('load', typeset)
    c.mjax.addEventListener('error', function (ev) {
      c.done = true
      c.status = 1
    })
    c.mjax.src = `${dirname}/node_modules/mathjax/unpacked/MathJax.js`
    document.body.appendChild(c.mjax)
  }, dirname)

  async function sleep (ms) {
    return new Promise((resolve) => {
      setTimeout(resolve, ms)
    })
  }

  let pageContentAfterSerialize = ''
  while (true) {
    clearTerminal()
    let mathDone = false
    mathDone = await page.evaluate(() => {
      const c = window.__c
      let msg = document.getElementById('MathJax_Message')
      if (msg && msg.innerText !== '') {
        console.log(`Progress: ${document.getElementById('MathJax_Message').innerText}`)
      }
      return c.done
    })
    await sleep(1000)
    if (mathDone) {
      clearTerminal()
      log.info('Serializing document...')
      pageContentAfterSerialize = await page.evaluate(() => {
        let s = new window.XMLSerializer()
        let d = document
        let str = s.serializeToString(d)
        console.log('All messages from MathJax:', JSON.stringify(window.MathJax.Message.Log()))
        return str
      })
      break
    }
  }

  log.info('Saving file...')
  await writeFile(output, pageContentAfterSerialize)
  clearTerminal()
  log.info(`Content saved. Open ${output} to see converted file. You can also check /logs folder for details.`)

  await browser.close()
}

module.exports = {
  injectMathJax
}
