const path = require('path')
require('dotenv').config()
const fs = require('fs')
const fileExists = require('file-exists')
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
