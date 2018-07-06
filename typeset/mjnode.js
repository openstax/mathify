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
    log.info('Config is set.')
    mjAPI.start()

    log.info('Starting conversion of mapped mathML elements with mathjax-node...')
    log.info(`There is ${Object.keys(mathMLElementsMap).length} elements to process...`)
    let convertedMathMLElements = {}
    let failedElementsIds = []
    let fullLength = Object.keys(mathMLElementsMap).length
    let progress = 0
    for(let i = 0; i < fullLength; i++){
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
                convertedMathMLElements[i] = `<span id="mjnode-failed-${i}" class="mjnode-failed">!!Conversion of equasion failed!!</span>`                
                log.debug(`Conversion of ${i} element crashed. Find this element by his id="mjnode-failed-${i}"`)    
                failedElementsIds.push(i)            
            }
        })

        let newProgress = Math.round((fullLength - (fullLength - i)) / fullLength * 100)
        if (Math.round(newProgress / 10) !== Math.round(progress / 10)){
            log.info(`Converted ${newProgress}% of all elements...`)
            progress = newProgress
        }
    }

    if (failedElementsIds.length){
        log.error(`Conversion of ${failedElementsIds.length} elements failed. You can find thouse elements by searching their class="mjnode-failed".`)
    }

    while(true){
        let a = Object.keys(convertedMathMLElements).length
        if (a < Object.keys(mathMLElementsMap).length){
            await sleep(1000)
        }else{
            break
        }
    }

    log.info(`Converted all ${Object.keys(convertedMathMLElements).length} elements.`)
    return convertedMathMLElements
}

module.exports = {
    convertMathML
}