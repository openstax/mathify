const mathjax = require('mathjax-full/js/mathjax.js').mathjax;
const MathML = require('mathjax-full/js/input/mathml.js').MathML;
const TeX = require('mathjax-full/js/input/tex.js').TeX;
const AllPackages = require('mathjax-full/js/input/tex/AllPackages.js').AllPackages;
const SVG = require('mathjax-full/js/output/svg.js').SVG;
const liteAdaptor = require('mathjax-full/js/adaptors/liteAdaptor.js').liteAdaptor;
const RegisterHTMLHandler = require('mathjax-full/js/handlers/html.js').RegisterHTMLHandler;

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
const mmlInputDoc = mathjax.document('', {InputJax: mml, OutputJax: svg});
const texInputDoc = mathjax.document('', {InputJax: tex, OutputJax: svg});

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
    const inputDoc = isMml ? mmlInputDoc : texInputDoc
   
    const node = inputDoc.convert(mathSource, {
      // display: true,
      // em: fontSize,
      ex: fontSize,
      // containerWidth: 44
    });

    const svg = adaptor.innerHTML(node)
    convertedMathMLElements.set(id, svg || html)

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
