const path = require('path')
require('dotenv').config()
const fs = require('fs')
const fileExists = require('file-exists')
const puppeteer = require('puppeteer')
const bunyan = require('bunyan')
const BunyanFormat = require('bunyan-format')
const mathJaxPath = require.resolve('mathjax/unpacked/MathJax')
const converter = require('./../converter')

const log = bunyan.createLogger({
  name: 'node-typeset',
  level: process.env.LOG_LEVEL || 'info',
  stream: new BunyanFormat({outputMode: process.env.LOG_FORMAT || 'short'})
})

let pathToInput = path.resolve('./typeset/tests/seed/test.xhtml')
let pathToCss = path.resolve('./typeset/tests/seed/test.css')
let pathToOutput = path.resolve('./typeset/tests/test-output.html')
let pathToOutputSVG = path.resolve('./typeset/tests/test-output-svg.html')
let mathJaxOutputFormat = 'HTML-CSS'

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
})

test('Fail if user provide wrong path for input file.', async (done) => {
  let res = await converter.injectMathJax(log, './wrong/path.xhtml', pathToCss, pathToOutput, mathJaxPath, mathJaxOutputFormat)
  expect(res).toBe(converter.STATUS_CODE.ERROR)
  done()
})

test('Fail if user provide wrong path for css file.', async (done) => {
  let res = await converter.injectMathJax(log, pathToInput, './wrong/path.xhtml', pathToOutput, mathJaxPath, mathJaxOutputFormat)
  expect(res).toBe(converter.STATUS_CODE.ERROR)
  done()
})

test('Success if output file with HTML-CSS format is created.', async (done) => {
  let res = await converter.injectMathJax(log, pathToInput, pathToCss, pathToOutput, mathJaxPath, mathJaxOutputFormat)
  let isOutputFile = false
  if (fileExists.sync(pathToOutput)) {
    isOutputFile = true
  }
  expect(res).toBe(converter.STATUS_CODE.OK)
  expect(isOutputFile).toBeTruthy()
  done()
}, 15000)

test('Success if output file with SVG format is created.', async (done) => {
  let res = await converter.injectMathJax(log, pathToInput, pathToCss, pathToOutputSVG, mathJaxPath, 'SVG')
  let isOutputFile = false
  if (fileExists.sync(pathToOutputSVG)) {
    isOutputFile = true
  }
  expect(res).toBe(converter.STATUS_CODE.OK)
  expect(isOutputFile).toBeTruthy()
  done()
}, 15000)

test('Test output file with HTML-CSS and SVG format for containing MathJax converted elements and do not contain MathML elements.', async (done) => {
  const browser = await puppeteer.launch({
    args: ['--no-sandbox'],
    devtools: process.env.BROWSER_DEBUGGER === 'true'
  })
  const page = await browser.newPage()
  await page.goto(`file://${pathToOutput}`)
  let resHTMLCSS = await page.evaluate(/* istanbul ignore next */() => {
    let res = {
      mathJaxClasses: 0,
      mathMLElements: 0
    }
    // Search for converted MathJax elements by their class names
    let mathJaxClassesToCheck = ['MathJax_Display']
    mathJaxClassesToCheck.forEach(el => {
      res.mathJaxClasses += document.getElementsByClassName(el).length
    })
    // Search for different types of MathML elements
    let mathMLElementsToCheck = ['m:math', 'math', 'm:semantics', 'semantics', 'm:mrow', 'mrow']
    mathMLElementsToCheck.forEach(el => {
      res.mathMLElements += document.getElementsByTagName(el).length
    })
    return res
  })

  await page.goto(`file://${pathToOutputSVG}`)
  let resSVG = await page.evaluate(/* istanbul ignore next */() => {
    let res = {
      mathJaxClasses: 0,
      mathMLElements: 0
    }
    // Search for converted MathJax elements by their class names
    let mathJaxClassesToCheck = ['MathJax_SVG']
    mathJaxClassesToCheck.forEach(el => {
      res.mathJaxClasses += document.getElementsByClassName(el).length
    })
    // Search for different types of MathML elements
    let mathMLElementsToCheck = ['m:math', 'math', 'm:semantics', 'semantics', 'm:mrow', 'mrow']
    mathMLElementsToCheck.forEach(el => {
      res.mathMLElements += document.getElementsByTagName(el).length
    })
    return res
  })
  await browser.close()

  expect(resHTMLCSS.mathJaxClasses).toBeGreaterThan(0)
  expect(resHTMLCSS.mathMLElements).toEqual(0)
  expect(resSVG.mathJaxClasses).toBeGreaterThan(0)
  expect(resSVG.mathMLElements).toEqual(0)
  done()
}, 15000)
