const path = require('path')
require('dotenv').config()
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

// Tests are not working for now
// Should we wrap injectMathJax with Promise and return Promise.reject(new Error(err)) instead of using process.exit?
test('Fail if user provide wrong path to input file.', async () => {
  let err = await converter.injectMathJax(log, './wrong/path.xhtml', pathToCss, pathToOutput, mathJaxPath)
  expect(err).toEqual('Input XHTML file not found.')
})

test('Success if everything is ok.', async () => {
  let res = await converter.injectMathJax(log, pathToInput, pathToCss, pathToOutput, mathJaxPath)
  expect(res).toBe('Success')
})
