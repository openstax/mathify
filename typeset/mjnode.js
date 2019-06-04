const mjAPI = require('mathjax-node')
let mjStarted = false

const startAPI = (log) => {
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
        font: 'STIXIntegralsUp',
        // mtextFontInherit: true,
        // Add fallback information to font-data:
        // https://github.com/mathjax/MathJax/issues/1091#issuecomment-269653429
        Argument: {
          initSVG: function(math, span) {
            if (this.config.font !== "TeX") {
              this.Augment({
                lookupChar_old: this.lookupChar,
                lookupChar: function (variant,n) {
                  do {
                    var char = this.lookupChar_old(variant,n);
                    if (char.id !== "unknown") return char;
                    variant = VARIANT[variant.chain];
                  } while (variant);
                  return char;
                }
              });
              var VARIANT = this.FONTDATA.VARIANT;
              VARIANT["bold"].chain = "normal";
              VARIANT["italic"].chain = "normal";
              VARIANT["bold-italic"].chain = "bold";
              VARIANT["double-struck"].chain = "normal";
              VARIANT["fraktur"].chain = "normal";
              VARIANT["bold-fraktur"].chain = "bold";
              VARIANT["script"].chain = "normal";
              VARIANT["bold-script"].chain = "bold";
              VARIANT["sans-serif"].chain = "normal";
              VARIANT["bold-sans-serif"].chain = "bold";
              VARIANT["sans-serif-italic"].chain = "italic";
              VARIANT["sans-serif-bold-italic"].chain = "bold-italic";
              VARIANT["monospace"].chain = "normal";
              VARIANT["-tex-caligraphic"].chain = "normal";
              VARIANT["-tex-oldstyle"].chain = "normal";
              VARIANT["-tex-caligraphic-bold"].chain = "bold";
              VARIANT["-tex-oldstyle-bold"].chain = "bold";
            }
            this.initSVG = function (math,span) {}
          }
        }
      }
    }
  })
  log.debug('Config is set. Starting mathjax-node service')
  mjAPI.start()
  mjStarted = true
}

const convertMathML = async (log, mathMap/*: Map<string, {xml: string, fontSize: number} */, outputFormat) => {
  if (!mjStarted) {
    startAPI(log)
  }

  const total = mathMap.size
  log.debug(`There are ${total} elements to process...`)
  log.info('Starting conversion of mapped MathML elements with mathjax-node...')
  const convertedMathMLElements = new Map()
  let prevTime = Date.now()
  let numDone = 0
  const convertedCss = new Set()
  const promises = [...mathMap.entries()].map(([id, {xml: mathSource, fontSize}]) => {
    return mjAPI.typeset({
      math: mathSource,
      format: mathSource[0] !== '\\' ? 'MathML' : 'inline-TeX', // "inline-TeX", "TeX", "MathML"
      svg: outputFormat === 'svg',
      html: outputFormat === 'html',
      css: outputFormat === 'html',
      ex: fontSize
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
        convertedMathMLElements.set(id, svg || html)
        // store css in a separate map to deduplicate
        if (!!css) {
          convertedCss.add(css)
        }
      })
  })

  await Promise.all(promises)
  log.debug(`Converted ${total} elements.`)
  log.info(`Converted all elements.`)
  return [convertedMathMLElements, [...convertedCss.keys()]]
}

module.exports = {
  convertMathML
}
