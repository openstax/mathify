const { scanXML } = require('../scan-xml')
const sax = require('sax')

test('handles nested elements correctly', () => {
  const matches = []
  const testNested = `\
<root>
  <a>
      <b>
          inside first b
          <b>
              inside second b
              <c>
                  something & "something else"
                  <b data-self-closing="true" />
              </c>
          </b>
      </b>
  </a>
</root>
`
  const parser = sax.parser(true)
  scanXML(
    parser,
    [{ tag: 'b' }],
    match => matches.push(match)
  )
  parser.write(testNested)

  expect(matches).toMatchSnapshot()
  expect(matches.length).toBe(3)
})

test('handles namespaces correctly', () => {
  const matches = []
  const testNamespaces = `\
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
                    this should have all the namespaces
                </c>
            </b>
        </a>
    </div>
    <div>
        <c>
            this should only have top-level namespaces (mathml, epub, xhtml)
        </c>
    </div>
</html>
`
  const parser = sax.parser(true)
  scanXML(
    parser,
    [
      { tag: 'math' },
      { tag: 'c' },
      { tag: 'b', attr: 'data-math' },
      { tag: 'img' }
    ],
    match => matches.push(match)
  )
  parser.write(testNamespaces)

  expect(matches).toMatchSnapshot()
  expect(matches.length).toBe(5)
})

test('throws an error with bad matchers', () => {
  let exception
  try {
    scanXML({}, [{ whatKindOfMatcherIsThisAnyway: '' }], () => {})
  } catch (e) {
    exception = e
  }
  expect(exception).toBeDefined()
  expect(exception.toString()).toContain('Unknown matcher type')
})

test('throws an error when there is cdata', () => {
  const matches = []
  const testCdata = '<root><![CDATA[Some character data]]></root>'
  const parser = sax.parser(true)
  scanXML(parser, [{ tag: 'root' }], match => matches.push(match))
  parser.write(testCdata)
  expect(matches).toMatchSnapshot()
  expect(matches.length).toBe(1)
})

test('records comments', () => {
  const matches = []
  const testComments = `\
<root>
  <a>
    <!--
      This is
      a
      multiline
      comment
    -->
  </a>
</root>
`
  const parser = sax.parser(true)
  scanXML(
    parser,
    [{ tag: 'a' }],
    match => matches.push(match)
  )
  parser.write(testComments)
  expect(matches).toMatchSnapshot()
  expect(matches.length).toBe(1)
})
