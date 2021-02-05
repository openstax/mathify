const path = require('path')
require('dotenv').config()
const fs = require('fs')
const fileExists = require('file-exists')
const puppeteer = require('puppeteer')
const bunyan = require('bunyan')
const BunyanFormat = require('bunyan-format')
const converter = require('./../converter')

const log = bunyan.createLogger({
  name: 'node-typeset',
  level: process.env.LOG_LEVEL || 'info',
  stream: new BunyanFormat({ outputMode: process.env.LOG_FORMAT || 'short' })
})

const pathToInput = path.resolve('./typeset/tests/seed/test.baked.xhtml')
const pathToCss = path.resolve('./typeset/tests/seed/test.css')
const pathToOutput = path.resolve('./typeset/tests/test-output.xhtml')
const pathToOutputSVG = path.resolve('./typeset/tests/test-output-svg.xhtml')
const pathToInputLatex = path.resolve('./typeset/tests/seed/test-latex.xhtml')
const pathToOutputLatex = path.resolve('./typeset/tests/test-output-latex.xhtml')

beforeAll(() => {
  if (fileExists.sync(pathToOutput)) {
    fs.unlink(pathToOutput, (err) => {
      if (err) throw err
    })
  }

  if (fileExists.sync(pathToOutputSVG)) {
    fs.unlink(pathToOutputSVG, (err) => {
      if (err) throw err
    })
  }

  if (fileExists.sync(pathToOutputLatex)) {
    fs.unlink(pathToOutputLatex, (err) => {
      if (err) throw err
    })
  }
})

afterAll(() => {
  if (fileExists.sync(pathToOutput)) {
    fs.unlink(pathToOutput, (err) => {
      if (err) throw err
    })
  }

  if (fileExists.sync(pathToOutputSVG)) {
    fs.unlink(pathToOutputSVG, (err) => {
      if (err) throw err
    })
  }

  if (fileExists.sync(pathToOutputLatex)) {
    fs.unlink(pathToOutputLatex, (err) => {
      if (err) throw err
    })
  }
})

test('Fail if user provide wrong path for input file (Math).', async (done) => {
  const res = await converter.createMapOfMathMLElements(log, './wrong/path.xhtml', pathToCss, pathToOutput, 'html', 3000)
  expect(res).toBe(converter.STATUS_CODE.ERROR)
  done()
})

test('Fail if user provide wrong path for css file.', async (done) => {
  const res = await converter.createMapOfMathMLElements(log, pathToInput, './wrong/path.xhtml', pathToOutput, 'html', 3000)
  expect(res).toBe(converter.STATUS_CODE.ERROR)
  done()
})

test('Success if converter finished without errors FORMAT HTML.', async (done) => {
  const res = await converter.createMapOfMathMLElements(log, pathToInput, pathToCss, pathToOutput, 'html', 3000)
  let isOutputFile = false
  if (fileExists.sync(pathToOutput)) {
    isOutputFile = true
  }
  expect(res).toBe(converter.STATUS_CODE.OK)
  expect(isOutputFile).toBeTruthy()
  done()
}, 30000)

test('Success if converter finished without errors FORMAT SVG.', async (done) => {
  const res = await converter.createMapOfMathMLElements(log, pathToInput, pathToCss, pathToOutputSVG, 'svg', 3000)
  let isOutputFile = false
  if (fileExists.sync(pathToOutputSVG)) {
    isOutputFile = true
  }
  expect(res).toBe(converter.STATUS_CODE.OK)
  expect(isOutputFile).toBeTruthy()
  done()
}, 30000)

test('Success if convertered LaTeX functions with success.', async (done) => {
  const res = await converter.createMapOfMathMLElements(log, pathToInputLatex, pathToCss, pathToOutputLatex, 'html', 3000)
  let isOutputFile = false
  if (fileExists.sync(pathToOutputLatex)) {
    isOutputFile = true
  }
  expect(res).toBe(converter.STATUS_CODE.OK)
  expect(isOutputFile).toBeTruthy()
  done()
}, 30000)

test('Check if there are MathJaxNode classes instead mathML elements.', async (done) => {
  const browser = await puppeteer.launch({
    args: ['--no-sandbox'],
    devtools: process.env.BROWSER_DEBUGGER === 'true'
  })
  const page = await browser.newPage()
  await page.goto(`file://${pathToOutput}`)
  const res = await page.evaluate(/* istanbul ignore next */() => {
    const res = {
      mjNodeClasses: 0,
      mathMLElements: 0
    }
    // Search for converted MathJax elements
    res.mjNodeClasses = document.getElementsByClassName('mjx-chtml').length
    // Search for different types of MathML elements
    res.mathMLElements += document.getElementsByTagNameNS('http://www.w3.org/1998/Math/MathML', 'math').length
    return res
  })
  await browser.close()

  expect(res.mjNodeClasses).toBeGreaterThan(0)
  expect(res.mathMLElements).toEqual(0)
  done()
}, 30000)

test('Check if there are SVGs instead mathML elements.', async (done) => {
  const browser = await puppeteer.launch({
    args: ['--no-sandbox'],
    devtools: process.env.BROWSER_DEBUGGER === 'true'
  })
  const page = await browser.newPage()
  await page.goto(`file://${pathToOutputSVG}`)
  const res = await page.evaluate(/* istanbul ignore next */() => {
    const res = {
      svgs: 0,
      mathMLElements: 0
    }
    // Search for converted MathJax elements
    res.svgs = document.getElementsByTagName('svg').length
    // Search for different types of MathML elements
    res.mathMLElements += document.getElementsByTagNameNS('http://www.w3.org/1998/Math/MathML', 'math').length
    return res
  })
  await browser.close()

  expect(res.svgs).toBeGreaterThan(0)
  expect(res.mathMLElements).toEqual(0)
  done()
}, 30000)

test('Check if LaTeX functions was converted correctly.', async (done) => {
  const browser = await puppeteer.launch({
    args: ['--no-sandbox'],
    devtools: process.env.BROWSER_DEBUGGER === 'true'
  })
  const page = await browser.newPage()
  await page.goto(`file://${pathToOutputLatex}`)
  const res = await page.evaluate(/* istanbul ignore next */() => {
    // if (document.querySelector('parsererror')) {
    //   throw new Error(`parsererror: ${document.querySelector('parsererror').textContent}`)
    // }
    const res = {
      dataMath: 0,
      mjNodeClasses: 0
    }
    // Search for converted MathJax elements
    res.dataMath = document.querySelectorAll('[data-math]').length
    // Search for different types of MathML elements
    res.mjNodeClasses += document.getElementsByClassName('mjx-chtml').length
    res.html = document.getElementsByTagName('body')[0].innerHTML
    return res
  })
  await browser.close()
  expect(res.mjNodeClasses).toBeGreaterThan(0)
  expect(res.dataMath).toEqual(0)
  done()
}, 30000)

test('Check if `pre` elements with lang attribute are highlighted', async (done) => {
  const browser = await puppeteer.launch({
    args: ['--no-sandbox'],
    devtools: process.env.BROWSER_DEBUGGER === 'true'
  })
  const page = await browser.newPage()
  await page.goto(`file://${pathToOutput}`)
  const res = await page.evaluate(() => {
    const res = {
      hljsClasses: 0
    }
    res.hljsClasses = document.querySelectorAll('pre > span[class*="hljs-"]').length
    return res
  })
  await browser.close()

  expect(res.hljsClasses).toBeGreaterThan(0)
  done()
})

test('Fail if `pre` tag has no data-lang attribute value', async (done) => {
  const browser = await puppeteer.launch({
    args: ['--no-sandbox'],
    devtools: process.env.BROWSER_DEBUGGER === 'true'
  })
  const page = await browser.newPage()
  await page.goto(`file://${pathToOutput}`)
  const res = await page.evaluate(() => {
    const preTagElements = document.querySelectorAll('pre[data-lang]')
    const res = {
      missingAttrValue: false,
      missing: 0
    }
    preTagElements.forEach(pre => {
      if (pre.getAttribute('data-lang') === '') {
        res.missing++
        res.missingAttrValue = true
      }
    })
    return res
  })
  await browser.close()
  expect(res.missingAttrValue).toEqual(false)
  expect(res.missing).toEqual(0)
  done()
})
