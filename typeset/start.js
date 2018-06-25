const path = require('path')
const fs = require('fs')
const yargs = require('yargs')
const fileExists = require('file-exists')
require('dotenv').config()
const bunyan = require('bunyan')
let level = process.env.LOG_LEVEL || 'info'
if (!fs.existsSync(`${__dirname}/logs`)) {
  fs.mkdirSync(`${__dirname}/logs`)
}
let log = bunyan.createLogger({
  name: 'typeset start',
  streams: [
    {
      level: level,
      stream: process.stdout
    },
    {
      type: 'rotating-file',
      path: path.join(__dirname, `/logs/log-typeset-start-${Date.now()}.log`),
      period: '1d',
      count: 30
    }
  ]
})

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
  let pathToInput = path.join(__dirname, argv['input'])
  let pathToCss = path.join(__dirname, argv['css'])
  if (fileExists.sync(pathToInput) && fileExists.sync(pathToCss)) {
    log.info(`Starting injecting MathJax to ${argv['input']}`)
    converter.injectMathJax(pathToInput.replace(/\\/g, '/'), argv['css'], argv['output'], __dirname)
  } else {
    log.error('Input or css file not found.')
  }
}
