function escapeXml (unsafe) {
  return unsafe.replace(/[<>&'"]/g, function (c) {
    switch (c) {
      case '<': return '&lt;'
      case '>': return '&gt;'
      case '&': return '&amp;'
      case '\'': return '&apos;'
      case '"': return '&quot;'
    }
  })
}

function reduceMatchers (matchers) {
  return matchers.map(matcher => {
    const conditions = []
    for (const k of Object.keys(matcher)) {
      switch (k) {
        case 'tag':
          conditions.push(node => (
            node.name.endsWith(`:${matcher.tag}`) || node.name === matcher.tag
          ))
          break
        case 'attr':
          conditions.push(node => (
            Object.keys(node.attributes).some(k =>
              k.endsWith(`:${matcher.attr}`) || k === matcher.attr
            )
          ))
          break
        default:
          throw new Error(`Unknown matcher type "${k}"`)
      }
    }
    return conditions.reduce((ax, x) => n => x(n) && ax(n))
  })
}

function scanXML (saxParser, matchersRaw, onMatch) {
  const matchers = reduceMatchers(matchersRaw)
  const recorderGroups = new Map(matchers.map(m => [m, []]))
  const namespaceStack = []
  let nsString = ''

  saxParser.onopentag = function (node) {
    for (const k in node.attributes) {
      if (k.startsWith('xmlns')) {
        namespaceStack.push({
          tag: node.name,
          namespaces: Object.entries(node.attributes)
            .filter(([k, _]) => k.startsWith('xmlns'))
            .map(([k, v]) => `${k}="${v}"`)
            .join(' ')
        })
        nsString = namespaceStack.map(({ namespaces }) => namespaces).join(' ')
        break
      }
    }
    for (const recorderGroup of recorderGroups.values()) {
      if (recorderGroup.length === 0) continue
      // I wish I could figure a way to only build this string once
      const attr = Object.entries(node.attributes).map(([k, v]) =>
        `${k}="${escapeXml(v)}"`
      ).join(' ')
      for (const { sb } of recorderGroup) {
        sb.push(`<${node.name} ${attr}>`)
      }
    }
    for (const matcher of matchers) {
      if (matcher(node)) {
        const recorderGroup = recorderGroups.get(matcher)
        const attr = Object.entries(node.attributes).map(([k, v]) =>
          `${k}="${escapeXml(v)}"`
        ).join(' ')
        recorderGroup.push({
          tag: node.name,
          node,
          sb: [`<${node.name} ${nsString} ${attr}>`],
          posStart: [
            saxParser.line + 1,
            saxParser.column - (saxParser.position - saxParser.startTagPosition)
          ]
        })
      }
    }
  }

  saxParser.onclosetag = function (tag) {
    if (namespaceStack.length && tag === namespaceStack[namespaceStack.length - 1].tag) {
      namespaceStack.pop()
      nsString = namespaceStack.map(({ namespaces }) => namespaces).join(' ')
    }
    for (const recorderGroup of recorderGroups.values()) {
      if (recorderGroup.length === 0) continue
      for (const { sb } of recorderGroup) {
        if (saxParser.tag.isSelfClosing) {
          sb.push(sb.pop().slice(0, -1) + '/>')
        } else {
          sb.push(`</${tag}>`)
        }
      }
      if (recorderGroup[recorderGroup.length - 1].tag === tag) {
        const recorder = recorderGroup.pop()
        recorder.posEnd = [saxParser.line + 1, saxParser.column + 1]
        recorder.element = recorder.sb.join('')
        delete recorder.sb
        onMatch(recorder)
      }
    }
  }

  const simpleAppend = function (text) {
    for (const recorderGroup of recorderGroups.values()) {
      if (recorderGroup.length === 0) continue
      for (const { sb } of recorderGroup) {
        sb.push(text)
      }
    }
  }

  saxParser.ontext = text => simpleAppend(escapeXml(text))

  saxParser.oncomment = comment => simpleAppend(`<!--${comment}-->`)

  saxParser.onopencdata = () => simpleAppend('<![CDATA[')
  saxParser.oncdata = cdata => simpleAppend(escapeXml(cdata))
  saxParser.onclosecdata = () => simpleAppend(']]>')
}

module.exports = {
  scanXML
}
