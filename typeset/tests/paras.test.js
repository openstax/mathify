const { EventEmitter } = require('events')
const { PARAS } = require('../paras')

class FakeReadStream extends EventEmitter {
  start (content, chunkSize) {
    let offset = 0

    const chunks = Math.ceil(content.length / chunkSize)
    for (let i = 0; i < chunks; i++) {
      this.emit('data', content.slice(offset, offset + chunkSize))
      offset += chunkSize
    }
    this.emit('end')
  }
}

class FakeWriteStream {
  constructor () {
    this.sb = []
  }

  write (chunk) {
    this.sb.push(chunk)
  }

  getValue () {
    return this.sb.join('')
  }
}

const fakeFile = `\
This is a test
1
2
3`

test('replace stuff', () => {
  const reader = new FakeReadStream()
  const writer = new FakeWriteStream()
  PARAS(
    [
      // Replace ' is' with ' IS'
      { posStart: [1, 5], posEnd: [1, 8], chunk: ' IS' },
      // Replace 'a test\n' with ''
      { posStart: [1, 9], posEnd: [2, 1], chunk: '' }
    ],
    reader,
    writer
  )
  reader.start(fakeFile, 2)
  expect(writer.getValue()).toMatchSnapshot()
})

test('replace stuff with larger chunk size', () => {
  const reader = new FakeReadStream()
  const writer = new FakeWriteStream()
  PARAS(
    [
      // Replace ' is' with ' IS'
      { posStart: [1, 5], posEnd: [1, 8], chunk: ' IS' },
      // Replace 'a test\n' with ''
      { posStart: [1, 9], posEnd: [2, 1], chunk: '' }
    ],
    reader,
    writer
  )
  reader.start(fakeFile, 2000)
  expect(writer.getValue()).toMatchSnapshot()
})

test('nothing to replace', () => {
  const reader = new FakeReadStream()
  const writer = new FakeWriteStream()
  PARAS(
    [],
    reader,
    writer
  )
  reader.start(fakeFile, 2)
  expect(writer.getValue()).toMatchSnapshot()
})

test('two replacements on one line', () => {
  const reader = new FakeReadStream()
  const writer = new FakeWriteStream()
  PARAS(
    [
      // replace ' is' with ''
      { posStart: [1, 5], posEnd: [1, 8], chunk: '' },
      // replace 'a ' with ''
      { posStart: [1, 9], posEnd: [1, 11], chunk: '' }
    ],
    reader,
    writer
  )
  reader.start(fakeFile, 2)
  expect(writer.getValue()).toMatchSnapshot()
})

test('replace more lines', () => {
  const longerFake = `\
yo1
yo2
yo3
yo4
yo5`
  const reader = new FakeReadStream()
  const writer = new FakeWriteStream()
  PARAS(
    [
      { posStart: [2, 1], posEnd: [4, 1], chunk: '' }
    ],
    reader,
    writer
  )
  reader.start(longerFake, 2)
  expect(writer.getValue()).toMatchSnapshot()
})

test('integration with xml scanner', () => {
  const sax = require('sax')
  const { scanXML } = require('../scan-xml')
  const testDocument = `\
<?xml version='1.0' encoding='UTF-8'?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:m="http://www.w3.org/1998/Math/MathML" xmlns:epub="http://www.idpf.org/2007/ops">
  <m:math>
    <m:msup><m:mn>2</m:mn><m:mn>2</m:mn></m:msup><m:mi>=</m:mi><m:mn>4</m:mn>
    <m:mn>3</m:mn><m:mi>&gt;</m:mi><m:mn>2</m:mn>
    <m:mi>&apos;</m:mi>x
  </m:math>
  <img xmlns:why="would-you-do-this" why:maybe="for this reason"/>
  <div xmlns:otherns="something-i-made-up">
    <a>
      <b data-math="i &lt; 3\pi">
        <c>
          <m:math>
            Things inside this tag
          </m:math>
        </c>
      </b>
    </a>
  </div>
  <div>
    <c>
        Other stuff that is not math
    </c>
  </div>
</html>
`
  const reader = new FakeReadStream()
  const writer = new FakeWriteStream()
  const parser = sax.parser(true)
  const mathEntries = []
  scanXML(
    parser,
    [{ tag: 'math' }],
    match => {
      match.chunk = `Replaced math from ${match.posStart} to ${match.posEnd}`
      mathEntries.push(match)
    }
  )
  parser.write(testDocument)
  console.log(mathEntries)
  PARAS(mathEntries, reader, writer)
  reader.start(testDocument, 63535)
  expect(writer.getValue()).toMatchSnapshot()
})
