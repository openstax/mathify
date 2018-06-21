const fs = require('fs')
const pify = require('pify')
const puppeteer = require('puppeteer')

const writeFile = pify(fs.writeFile)

const injectMathJax = async (inputPath, cssPath, outputPath) => {
  function clearTerminal(){
    if(process.platform == 'darwin'){
      process.stdout.write('\033c')
    }else if(process.platform == 'win32'){
      process.stdout.write('\033c')
    }
  }

  const url = `file://${inputPath}`
  const stylemj = `${cssPath}`
  const output = `${outputPath}`

  console.log('Starting puppeteer...')
  const browser = await puppeteer.launch({args: ['--no-sandbox']})
  const page = await browser.newPage()

  page.on('console', msg => console.log('PAGE LOG:', msg.text()))

  await page.goto(url)

  await page.evaluate(function () {
    window.__c = {
      done: false,
      status: 0
    }

    console.log('Removing non-breaking spaces...')
    let b = document.body
    let withoutSpaces = b.innerHTML.replace(/&nbsp;/g,' ')
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

  await page.evaluate(() => {
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
    c.mjax.src = './node_modules/mathjax/unpacked/MathJax.js'
    document.body.appendChild(c.mjax)
  })

  async function sleep (ms) {
    return new Promise((resolve) => {
      setTimeout(resolve, ms)
    })
  }
  
  var pageContentAfterSerialize = '';
  while (true) {
    clearTerminal()
    var mathDone = false
    mathDone = await page.evaluate(() => {
      const c = window.__c
      let msg = document.getElementById('MathJax_Message')
      if(msg && msg.innerText !== ''){
        console.log(`Progress: ${document.getElementById('MathJax_Message').innerText}`)
      }
      return c.done
    })
    await sleep(1000)
    if (mathDone) {
      clearTerminal()
      console.log('Serializing document...')
      pageContentAfterSerialize = await page.evaluate(() => {
        var s = new XMLSerializer()
        var d = document
        var str = s.serializeToString(d)
        return str;
      })
      break
    }
  }

  //const htmlOut = await page.content()

  console.log('Saving file...')
  await writeFile(output, pageContentAfterSerialize)
  clearTerminal()
  console.log(`Content saved. Open ${output} to see converted file.`)

  await browser.close()
}

module.exports = {
  injectMathJax
}
