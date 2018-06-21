const fs = require('fs')
const pify = require('pify')
const puppeteer = require('puppeteer')

const writeFile = pify(fs.writeFile)

const argv = {
  path: __dirname,
  input: process.argv[2],
  css: process.argv[3],
  output: process.argv[4]
}

const converter = require('./converter.js')

if(process.argv.length !== 5){
  console.log('Wrong commands. Use node start input.xhtml css.css output.html')
}else{
  let pathToInput = argv.path + '/' + argv.input
  console.log(`Starting injecting MathJax to ${argv.input}`)
  converter.injectMathJax(pathToInput.replace(/\\/g, "/"), argv.css, argv.output)
}