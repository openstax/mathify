const { TexMmlToSvg, TexToMml } = require('./converters')

const typesetOptions = {
  display: false
}

const getConverter = (outputFormat, options) => {
  const combinedOptions = { typesetOptions, ...options }
  switch (outputFormat) {
    case 'mathml': return new TexToMml(combinedOptions)
    case 'svg': return new TexMmlToSvg(combinedOptions)
    default: throw new Error(`Unknown output format: ${outputFormat}`)
  }
}

const convertMathML = async (log, mathEntries, outputFormat, batchSize, handleErrors, options) => {
  log.debug(`There are ${mathEntries.length} elements to process...`)
  log.debug('Starting conversion of mapped MathML elements with mathjax-node...')
  const convertedCss = new Set()
  const converter = getConverter(outputFormat, options)
  await converter.init()
  converter.addHook('progress', ({ args: { from, to, total } }) => {
    log.info(`Converting math elements ${from} to ${to} of ${total}`)
  })
  converter.addHook('diagnostic', ({ args: diag }) => {
    log.warn(
      diag.type === 'no_speech'
        ? `Failed to generate speech: ${diag.source}`
        : diag
    )
  })
  const errorPairs = []
  const math = mathEntries.map(({ mathSource }) => mathSource)
  const results = await converter.convert(math, batchSize)
  results.forEach(({ math, error, css }, idx) => {
    const entry = mathEntries[idx]
    if (error) {
      console.error(error.message)
      errorPairs.push([[error.message, error.source].join('\n'), entry])
    } else {
      if (math) entry.substitution = math.replace(/&nbsp;/g, '&#160;')
      if (css) convertedCss.add(css)
    }
  })
  if (errorPairs.length > 0) {
    handleErrors(errorPairs)
  }
  log.info(`Converted ${results.length} elements.`)
  converter.done()
  return new Set(...convertedCss.keys())
}

module.exports = {
  convertMathML
}
