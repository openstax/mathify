const  mjAPI = require("mathjax-node")

// Helper so we can write `await sleep(1000)`
async function sleep (ms) {
    return new Promise((resolve) => {
      setTimeout(resolve, ms)
    })
  }

const convertMathML = async (log, mathMLElementsMap) => {
    log.info('Setting config for MathJaxNode...')
    mjAPI.config({
        MathJax: {
            // traditional MathJax configuration
        }
    })
    mjAPI.start()

    let convertedMathMLElements = {}
    for(let i = 0; i < Object.keys(mathMLElementsMap).length; i++){
        let mathToProcess = mathMLElementsMap[i]
    
        mjAPI.typeset({
            math: mathToProcess,
            format: "MathML", // "inline-TeX", "TeX", "MathML"
            svg:true,      // svg:true, mml:true, html:true
            }, function (data) {
            if (!data.errors) {
                convertedMathMLElements[i] = data.svg
                log.debug(`Converted ${i} element`)
            }else{
                log.error(`Conversion of ${i} element crashed`)                
                convertedMathMLElements[i] = "error"
            }
        })
    }

    while(true){
        let a = Object.keys(convertedMathMLElements).length
        if (a < Object.keys(mathMLElementsMap).length){
            await sleep(1000)
        }else{
            break
        }
    }

    log.info(`Converted ${Object.keys(convertedMathMLElements).length} elements.`)
    return convertedMathMLElements
}

module.exports = {
    convertMathML
}