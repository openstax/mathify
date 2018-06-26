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

if (fileExists.sync(pathToOutput)) {
  fs.unlink(pathToOutput, (err) => {
    if (err) throw err
  })
}

test('Fail if user provide wrong path for input file.', async (done) => {
  let res = await converter.injectMathJax(log, './wrong/path.xhtml', pathToCss, pathToOutput, mathJaxPath)
  expect(res).toBe(converter.STATUS_CODE.ERROR)
  done()
})

test('Fail if user provide wrong path for css file.', async (done) => {
  let res = await converter.injectMathJax(log, pathToInput, './wrong/path.xhtml', pathToOutput, mathJaxPath)
  expect(res).toBe(converter.STATUS_CODE.ERROR)
  done()
})

test('Success if everything is ok.', async (done) => {
  let res = await converter.injectMathJax(log, pathToInput, pathToCss, pathToOutput, mathJaxPath)
  let isOutputFile = false
  if (fileExists.sync(pathToOutput)) {
    isOutputFile = true
  }
  expect(res).toBe(converter.STATUS_CODE.OK)
  expect(isOutputFile).toBeTruthy()
  done()
}, 15000)

test('Test output file for containing MathJax converted elements and do not contain MathML elements.', async (done) => {
  const browser = await puppeteer.launch({
    args: ['--no-sandbox'],
    devtools: process.env.BROWSER_DEBUGGER === 'true'
  })
  const page = await browser.newPage()
  await page.goto(`file://${pathToOutput}`)
  let res = await page.evaluate(() => {
    let res = {
      mathJaxClasses: 0,
      mathMLElements: 0
    }
    // Search for converted MathJax elements
    res.mathJaxClasses = document.getElementsByClassName('MathJax_Display').length
    // Search for different types of MathML elements
    res.mathMLElements += document.getElementsByTagName('m:math').length
    res.mathMLElements += document.getElementsByTagName('math').length
    res.mathMLElements += document.getElementsByTagName('m:semantics').length
    res.mathMLElements += document.getElementsByTagName('semantics').length
    res.mathMLElements += document.getElementsByTagName('m:mrow').length
    res.mathMLElements += document.getElementsByTagName('mrow').length
    return res
  })
  await browser.close()

  expect(res.mathJaxClasses).toBeGreaterThan(0)
  expect(res.mathMLElements).toEqual(0)
  done()
}, 15000)
