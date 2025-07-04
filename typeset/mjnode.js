const path = require('path')
const mjAPI = require('mathjax-node')
const { assertTrue } = require('./helpers')
let mjStarted = false

const startAPI = (log) => {
  log.debug('Setting config for MathJaxNode...')
  mjAPI.config({
    displayMessages: false, // determines whether Message.Set() calls are logged
    displayErrors: true, // determines whether error messages are shown on the console
    undefinedCharError: false, // determines whether "unknown characters" (i.e., no glyph in the configured fonts) are saved in the error array
    extensions: '[extensions]/minFontSize.js',
    paths: { extensions: path.join(__dirname, 'extensions') },
    MathJax: {
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
        font: 'STIX-Web',
        scale: 40,
        blacker: 0,
        // mtextFontInherit: true,
        // Add fallback information to font-data:
        // https://github.com/mathjax/MathJax/issues/1091#issuecomment-269653429
        Argument: {
          initSVG: function (math, span) {
            if (this.config.font !== 'TeX') {
              this.Augment({
                lookupChar_old: this.lookupChar,
                lookupChar: function (variant, n) {
                  do {
                    var char = this.lookupChar_old(variant, n)
                    if (char.id !== 'unknown') return char
                    variant = VARIANT[variant.chain]
                  } while (variant)
                  return char
                }
              })
              var VARIANT = this.FONTDATA.VARIANT
              VARIANT.bold.chain = 'normal'
              VARIANT.italic.chain = 'normal'
              VARIANT['bold-italic'].chain = 'bold'
              VARIANT['double-struck'].chain = 'normal'
              VARIANT.fraktur.chain = 'normal'
              VARIANT['bold-fraktur'].chain = 'bold'
              VARIANT.script.chain = 'normal'
              VARIANT['bold-script'].chain = 'bold'
              VARIANT['sans-serif'].chain = 'normal'
              VARIANT['bold-sans-serif'].chain = 'bold'
              VARIANT['sans-serif-italic'].chain = 'italic'
              VARIANT['sans-serif-bold-italic'].chain = 'bold-italic'
              VARIANT.monospace.chain = 'normal'
              VARIANT['-tex-caligraphic'].chain = 'normal'
              VARIANT['-tex-oldstyle'].chain = 'normal'
              VARIANT['-tex-caligraphic-bold'].chain = 'bold'
              VARIANT['-tex-oldstyle-bold'].chain = 'bold'
            }
            this.initSVG = function (math, span) {}
          }
        }
      }
    }
  })
  log.debug('Config is set. Starting mathjax-node service')
  mjAPI.start()
  mjStarted = true
}

const convertMathML = async (log, mathEntries, outputFormat, total, done, handleErrors) => {
  if (!mjStarted) {
    startAPI(log)
  }

  log.debug(`There are ${total} elements to process...`)
  log.debug('Starting conversion of mapped MathML elements with mathjax-node...')
  let prevTime = Date.now()
  let numDone = done
  const convertedCss = new Set()
  let index = 0
  const errorPairs = []
  const promises = mathEntries.map(entry => {
    const id = done + index
    const mathSource = entry.mathSource
    index++
    const typesetConfig = {
      math: mathSource,
      format: mathSource.match('^<([^:]+:)?math') ? 'MathML' : 'inline-TeX', // "inline-TeX", "TeX", "MathML"
      svg: outputFormat === 'svg',
      html: outputFormat === 'html',
      mml: outputFormat === 'mathml',
      css: outputFormat === 'html',
      ex: 11 // pixels tall
    }
    log.debug(`Typeset config: ${JSON.stringify(typesetConfig)}`)
    return mjAPI.typeset(typesetConfig)
      .then((result) => {
        const { errors, svg, css, html, mml } = result
        /* istanbul ignore next (I don't think this actually works as expected) */
        if (errors) {
          log.fatal(errors)
          throw new Error(`Problem converting using MathJax. id="${id}"`)
        }
        numDone++

        // Print progress every 10 seconds
        const now = Date.now()
        /* istanbul ignore next (testing this would require some pretty big changes) */
        if (now - prevTime > 10 * 1000 /* 10 seconds */) {
          const percent = Math.floor(100 * numDone / total)
          log.info(`Typesetting Progress: ${percent}%`)
          prevTime = now
        }
        if (mml) {
          // mml should not contain &nbsp;
          assertTrue(mml.indexOf('&nbsp;') === -1, 'I thought this output was more strict!')
          entry.substitution = mml
        } else {
          // remove &nbsp; since it is not valid XHTML
          entry.substitution = (svg || html)?.replace(/&nbsp;/g, '&#160;')
        }
        // store css in a separate map to deduplicate
        if (css != null) {
          convertedCss.add(css)
        }
      }).catch((err) => { errorPairs.push([err, entry]) })
  })

  await Promise.all(promises)
  if (errorPairs.length > 0) {
    handleErrors(errorPairs)
    throw new Error('An error occurred while converting math.')
  }
  log.info(`Converted ${numDone} elements.`)
  return [...convertedCss.keys()]
}

module.exports = {
  convertMathML
}
