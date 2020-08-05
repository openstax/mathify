const mathjax = require('mathjax-full/js/mathjax.js').mathjax;
const MathML = require('mathjax-full/js/input/mathml.js').MathML;
const TeX = require('mathjax-full/js/input/tex.js').TeX;
const AllPackages = require('mathjax-full/js/input/tex/AllPackages.js').AllPackages;
const SVG = require('mathjax-full/js/output/svg.js').SVG;
const CHTML = require('mathjax-full/js/output/chtml.js').CHTML;
const liteAdaptor = require('mathjax-full/js/adaptors/liteAdaptor.js').liteAdaptor;
const RegisterHTMLHandler = require('mathjax-full/js/handlers/html.js').RegisterHTMLHandler;

// https://github.com/mathjax/MathJax/issues/2402#issuecomment-614867371
// Caused by <munder><mtext>long sentence</mtext><mo stretchy="true">︸</mo></munder>
const SVGWrapper = require('mathjax-full/js/output/svg/Wrapper').SVGWrapper;
const CommonWrapper = require('mathjax-full/js/output/common/Wrapper').CommonWrapper;
if (mathjax.version === '3.0.5') {
  SVGWrapper.prototype.unicodeChars = function (text, variant) {
    if (!variant) variant = this.variant || 'normal';
    return CommonWrapper.prototype.unicodeChars.call(this, text, variant);
  }
}

//
//  Create DOM adaptor and register it for HTML documents
//
const adaptor = liteAdaptor();
RegisterHTMLHandler(adaptor);

//
//  Create input and output jax and a document using them on the content from the HTML file
//
const mml = new MathML();
const tex = new TeX({packages: AllPackages.sort()});
const svg = new SVG({fontCache: (true ? 'local' : 'none')});
const chtml = new CHTML(/*{fontURL: 'https://cdnjs.cloudflare.com/ajax/libs/mathjax/3.0.0/es5/output/chtml/fonts/woff-v2'}*/);


const docsMatrix = {
  mml: {
    svg:    mathjax.document('', {InputJax: mml, OutputJax: svg}),
    chtml:  mathjax.document('', {InputJax: mml, OutputJax: chtml}),
  },
  tex: {
    svg:    mathjax.document('', {InputJax: tex, OutputJax: svg}),
    chtml:  mathjax.document('', {InputJax: tex, OutputJax: chtml}),
  }
}

const outputMatrix = {
  svg,
  chtml
}

const convertMathML = async (log, mathEntries/* [{xml: string, fontSize: number}, ...] */, outputFormat, total, done) => {

  log.debug(`There are ${total} elements to process...`)
  log.debug('Starting conversion of mapped MathML elements with mathjax3...')
  const convertedMathMLElements = new Map()
  let prevTime = Date.now()
  let numDone = done
  const convertedCss = new Set()
  let index = 0
  const promises = mathEntries.map(({xml: mathSource, fontSize}) => {
    const id = done + index
    index++

    const isMml = mathSource.match('^<([^:]+:)?math')
    const outFormatName = outputFormat === 'svg' ? 'svg' : 'chtml'
    const inputDoc = docsMatrix[isMml ? 'mml' : 'tex'][outFormatName]

    try {
      const node = inputDoc.convert(mathSource, {
        // display: true,
        // em: fontSize,
        ex: fontSize,
        // containerWidth: 44
      });
  
      const output = adaptor.innerHTML(node)
      convertedMathMLElements.set(id, output)
      convertedCss.add(adaptor.textContent(outputMatrix[outFormatName].styleSheet(node)))
    } catch (err) {
      log.info(mathSource)
      log.fatal(err)
      throw new Error(err.message)
    }

    numDone++

    // Print progress every 10 seconds
    const now = Date.now()
    if (now - prevTime > 10 * 1000 /* 10 seconds */) {
      const percent = Math.floor(100 * numDone / total)
      log.info(`Typesetting Progress: ${percent}%`)
      prevTime = now
    }

  })

  await Promise.all(promises)
  log.info(`Converted ${numDone} elements.`)
  return [convertedMathMLElements, [...convertedCss.keys()]]
}

module.exports = {
  convertMathML
}
