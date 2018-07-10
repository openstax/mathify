const mjAPI = require('mathjax-node')

const convertMathML = async (log, mathMap) => {
  log.debug('Setting config for MathJaxNode...')
  mjAPI.config({
    displayMessages: false, // determines whether Message.Set() calls are logged
    displayErrors: true, // determines whether error messages are shown on the console
    undefinedCharError: false, // determines whether "unknown characters" (i.e., no glyph in the configured fonts) are saved in the error array
    extensions: '',
    MathJax: {
      extensions: ['MatchWebFonts.js'],
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
  })
  log.debug('Config is set. Starting mathjax-node service')
  mjAPI.start()

  const total = mathMap.size
  log.debug(`There are ${total} elements to process...`)
  log.info('Starting conversion of mapped MathML elements with mathjax-node...')
  const convertedMathMLElements = new Map()
  let prevTime = Date.now()
  let numDone = 0
  const promises = [...mathMap.entries()].map(([id, mathSource]) => {
    return mjAPI.typeset({
      math: mathSource,
      format: 'MathML', // "inline-TeX", "TeX", "MathML"
      svg: true // svg:true, mml:true, html:true
      // html: true,
      // css: true
    })
      .then((result) => {
        const {errors, svg, css} = result
        let {html} = result // later, remove &nbsp; since it is not valid XHTML
        if (errors) {
          log.fatal(errors)
          throw new Error(`Problem converting using MathJax. id="${id}"`)
        }
        numDone++

        // Print progress every 10 seconds
        const now = Date.now()
        if (now - prevTime > 10 * 1000 /* 10 seconds */) {
          const percent = Math.floor(100 * numDone / total)
          log.info(`Typesetting Progress: ${percent}%`)
          prevTime = now
        }
        // remove &nbsp; since it is not valid XHTML
        if (html) {
          html = html.replace(/&nbsp;/g, '&#160;')
        }
        convertedMathMLElements.set(id, {html, svg, css})
      })
  })

  await Promise.all(promises)
  log.debug(`Converted ${total} elements.`)
  log.info(`Converted all elements.`)
  return convertedMathMLElements
}

module.exports = {
  convertMathML
}
