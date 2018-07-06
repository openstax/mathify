const  mjAPI = require("mathjax-node")

const convertMathML = async (log, mathMap) => {
    log.info('Setting config for MathJaxNode...')
    mjAPI.config({
        displayMessages: false,    // determines whether Message.Set() calls are logged
        displayErrors:   true,     // determines whether error messages are shown on the console
        undefinedCharError: false, // determines whether "unknown characters" (i.e., no glyph in the configured fonts) are saved in the error array
        extensions: '',
        MathJax: {
            // traditional MathJax configuration
        }
    })
    log.info('Config is set.')
    mjAPI.start()
    async function mjTypeset(source) {
      return new Promise((resolve, reject) => {
        mjAPI.typeset({
          math: source,
          format: "MathML", // "inline-TeX", "TeX", "MathML"
          svg: true,      // svg:true, mml:true, html:true
        }, ({errors, svg, html}) => {
          if (errors) {
            reject(errors)
          } else {
            resolve(svg || html) // Depending on which output format was chosen
          }
        })
      })
    }

    const total = mathMap.size
    log.debug(`There are ${total} elements to process...`)
    log.info('Starting conversion of mapped mathML elements with mathjax-node...')
    const convertedMathMLElements = new Map()
    let prevPercent = 0
    let numDone = 0
    const promises = [...mathMap.entries()].map(([id, xml]) => {
        return mjTypeset(xml)
        .then((converted) => {
          numDone++
          const percent = Math.floor(100 * numDone / total)
          if (percent !== prevPercent) {
            if (total > 100) {
              log.info(`Typesetting Progress: ${percent}%`)
            }
            prevPercent = percent
          }
          convertedMathMLElements.set(id, converted)
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
