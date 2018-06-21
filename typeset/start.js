const fs = require('fs')
const pify = require('pify')
const puppeteer = require('puppeteer')
const yargs = require('yargs')
const writeFile = pify(fs.writeFile)
const fileExists = require('file-exists')
require('dotenv').config()
const bunyan = require('bunyan')
let level = process.env.LOG_LEVEL || 'info'
let log = bunyan.createLogger({name: 'typeset', level: level})

const inputOptions = {
  describe: 'Please set a path to input file.',
  demand: true,
  alias: 'i'
}
const cssOptions = {
  describe: 'Please set a path to css file.',
  demand: true,
  alias: 'c'
}
const outputOptions = {
  describe: 'Please set a path and name with extension to output file.',
  demand: true,
  alias: 'o'
}

const argv = yargs
  .command('typeset', 'Typeset command need 3 arguments to run: -i -c -o.', {
    input: inputOptions,
    css: cssOptions,
    output: outputOptions
  })
  .help()
  .argv

const converter = require('./converter.js')

if (argv['input'] === '' || argv['css'] === '' || argv['output'] === '') {
  log.error('Wrong commands. Use node start typeset input.xhtml css.css output.html')
} else {
  let pathToInput = __dirname + '/' + argv['input']
  let pathToCss = __dirname + '/' + argv['css']
  if (fileExists.sync(pathToInput) && fileExists.sync(pathToCss)) {
    log.info(`Starting injecting MathJax to ${argv['input']}`)
    converter.injectMathJax(pathToInput.replace(/\\/g, '/'), argv['css'], argv['output'], __dirname)
  } else {
    log.error('Input or css file not found.')
  }
}
