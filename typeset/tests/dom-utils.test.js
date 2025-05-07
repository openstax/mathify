const { ancestorOrSelf, parseXML } = require('../dom-utils')

describe('ancestorOrSelf', () => {
  it('stops gracefully', () => {
    const xmlStr = `
  <root>
    <a>
      <b>
        stuff
      </b>
    </a>
  </root>
  `
    const tree = parseXML(xmlStr)
    const b = Object.values(tree.getElementsByTagName('b'))[0]
    expect(b).toBeDefined();
    const visited = Array.from(ancestorOrSelf(b));
    expect(visited.map((node) => node.tagName)).toStrictEqual([
      'b', 'a', 'root'
    ])
  })
})