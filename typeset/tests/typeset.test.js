const path = require('path')
require('dotenv').config()
const fs = require('fs')
const fileExists = require('file-exists')
const bunyan = require('bunyan')
const BunyanFormat = require('bunyan-format')
const converter = require('./../converter')
const { createHash } = require('crypto')
const { MemoryReadStream, MemoryWriteStream, getLogLevel } = require('../helpers')

const log = bunyan.createLogger({
  name: 'node-typeset',
  level: getLogLevel('30'),
  stream: new BunyanFormat({ outputMode: process.env.LOG_FORMAT || 'short' })
})

const pathToInput = path.resolve('./typeset/tests/seed/test.baked.xhtml')
const pathToCss = path.resolve('./typeset/tests/seed/test.css')
const pathToOutput = path.resolve('./typeset/tests/test-output.xhtml')
const pathToOutputSVG = path.resolve('./typeset/tests/test-output-svg.xhtml')
const pathToInputLatex = path.resolve('./typeset/tests/seed/test-latex.xhtml')
const pathToOutputLatex = path.resolve('./typeset/tests/test-output-latex.xhtml')
const pathToOutputMML = path.resolve('./typeset/tests/test-output-mathml.xhtml')

const pathToCodeInput = path.resolve('./typeset/tests/seed/test-code.xhtml')
const pathToCodeOutput = path.resolve('./typeset/tests/seed/test-code.output.xhtml')

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

  if (fileExists.sync(pathToOutputMML)) {
    fs.unlink(pathToOutputMML, (err) => {
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

  if (fileExists.sync(pathToOutputMML)) {
    fs.unlink(pathToOutputMML, (err) => {
      if (err) throw err
    })
  }
})

function getHashFile (fpath) {
  return new Promise((resolve, reject) => {
    const hash = createHash('sha256')
    const reader = fs.createReadStream(fpath).setEncoding('utf8')
    reader.on('data', chunk => hash.update(chunk))
    reader.on('error', err => reject(err))
    reader.on('end', () => {
      resolve(hash.digest('hex'))
    })
  })
}

const createMapOfMathMLElements = async (log, inputPath, pathToCss, outputPath, outputFormat, batchSize, highlight) => {
  const getInputStream = () => fs.createReadStream(inputPath)
  const getOutputStream = () => fs.createWriteStream(outputPath)
  return await converter.createMapOfMathMLElements(log, getInputStream, pathToCss, getOutputStream, outputFormat, batchSize, highlight)
}

// test('Fail if user provide wrong path for input file (Math).', async (done) => {
//   const res = await createMapOfMathMLElements(log, './wrong/path.xhtml', pathToCss, pathToOutput, 'html', 3000, true)
//   expect(res).toBe(converter.STATUS_CODE.ERROR)
//   done()
// })

// test('Fail if user provide wrong path for css file.', async (done) => {
//   const res = await createMapOfMathMLElements(log, pathToInput, './wrong/path.xhtml', pathToOutput, 'html', 3000, true)
//   expect(res).toBe(converter.STATUS_CODE.ERROR)
//   done()
// })

test('Success if converter finished without errors FORMAT HTML.', async (done) => {
  const res = await createMapOfMathMLElements(log, pathToInput, pathToCss, pathToOutput, 'html', 3000, true)
  let isOutputFile = false
  if (fileExists.sync(pathToOutput)) {
    isOutputFile = true
  }
  expect(res).toBe(converter.STATUS_CODE.OK)
  expect(isOutputFile).toBeTruthy()
  expect(await getHashFile(pathToOutput)).toMatchSnapshot()
  done()
}, 30000)

test('Success if converter finished without errors FORMAT SVG.', async (done) => {
  const res = await createMapOfMathMLElements(log, pathToInput, pathToCss, pathToOutputSVG, 'svg', 3000, true)
  let isOutputFile = false
  if (fileExists.sync(pathToOutputSVG)) {
    isOutputFile = true
  }
  expect(res).toBe(converter.STATUS_CODE.OK)
  expect(isOutputFile).toBeTruthy()
  expect(await getHashFile(pathToOutputSVG)).toMatchSnapshot()
  done()
}, 30000)

test('Success if convertered LaTeX functions with success.', async (done) => {
  const res = await createMapOfMathMLElements(log, pathToInputLatex, pathToCss, pathToOutputLatex, 'html', 3000, true)
  let isOutputFile = false
  if (fileExists.sync(pathToOutputLatex)) {
    isOutputFile = true
  }
  expect(res).toBe(converter.STATUS_CODE.OK)
  expect(isOutputFile).toBeTruthy()
  expect(await getHashFile(pathToOutputLatex)).toMatchSnapshot()

  done()
}, 30000)

test('Success if convertered LaTeX to mathml with success.', async (done) => {
  const res = await createMapOfMathMLElements(log, pathToInputLatex, pathToCss, pathToOutputMML, 'mathml', 3000, true)
  let isOutputFile = false
  if (fileExists.sync(pathToOutputMML)) {
    isOutputFile = true
  }
  expect(res).toBe(converter.STATUS_CODE.OK)
  expect(isOutputFile).toBeTruthy()
  expect(await getHashFile(pathToOutputMML)).toMatchSnapshot()

  done()
}, 30000)

test('Convert inline code tags and block pre tags', async (done) => {
  const res = await createMapOfMathMLElements(log, pathToCodeInput, pathToCss, pathToCodeOutput, 'html', 3000, true)
  expect(fileExists.sync(pathToCodeOutput))
  expect(res).toBe(converter.STATUS_CODE.OK)
  expect(fs.readFileSync(pathToCodeOutput, 'utf-8')).toMatchSnapshot()
  done()
}, 3000)

test('something', async (done) => {
  const output = new MemoryWriteStream()
  const src = '<p><span data-math="\\frac56"></span></p>'
  const getInputStream = () => new MemoryReadStream(src)
  const getOutputStream = () => output
  const res = await converter.createMapOfMathMLElements(
    log, getInputStream, '', getOutputStream, 'mathml', 3000, false
  )
  expect(res).toBe(converter.STATUS_CODE.OK)
  expect(output.getValue()).toMatchSnapshot()
  done()
}, 3000)
