function looseTagEq (tag, eq) {
  return tag.endsWith(`:${eq}`) || tag === eq
}

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
          conditions.push(node => looseTagEq(node.name, matcher.tag))
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
  const recorders = []
  const nsStack = []
  let currentDepth = 0
  let nsString = ''

  saxParser.onopentag = function (node) {
    currentDepth++
    for (const k in node.attributes) {
      if (k.startsWith('xmlns')) {
        nsStack.push({
          depth: currentDepth,
          namespaces: Object.entries(node.attributes)
            .filter(([k, _]) => k.startsWith('xmlns'))
            .map(([k, v]) => `${k}="${v}"`)
            .join(' ')
        })
        nsString = nsStack.map(({ namespaces }) => namespaces).join(' ')
        break
      }
    }

    for (const { sb } of recorders) {
      const attr = Object.entries(node.attributes).map(([k, v]) =>
        `${k}="${escapeXml(v)}"`
      ).join(' ')
      sb.push(`<${node.name} ${attr}>`)
    }

    for (const matcher of matchers) {
      if (!matcher(node)) continue
      const attr = Object.entries(node.attributes).map(([k, v]) =>
          `${k}="${escapeXml(v)}"`
      ).join(' ')
      recorders.push({
        depth: currentDepth,
        node,
        tag: node.name,
        sb: [`<${node.name} ${nsString} ${attr}>`],
        posStart: [
          saxParser.line + 1,
          saxParser.column - (saxParser.position - saxParser.startTagPosition)
        ]
      })
    }
  }

  saxParser.onclosetag = function (tag) {
    if (nsStack.length && nsStack[nsStack.length - 1].depth === currentDepth) {
      nsStack.pop()
      nsString = nsStack.map(({ namespaces }) => namespaces).join(' ')
    }

    for (const { sb } of recorders) {
      if (saxParser.tag.isSelfClosing) {
        sb.push(sb.pop().slice(0, -1) + '/>')
      } else {
        sb.push(`</${tag}>`)
      }
    }

    if (recorders.length && recorders[recorders.length - 1].depth === currentDepth) {
      const recorder = recorders.pop()
      recorder.posEnd = [saxParser.line + 1, saxParser.column + 1]
      recorder.element = recorder.sb.join('')
      delete recorder.sb
      delete recorder.depth
      onMatch(recorder)
    }
    currentDepth--
  }

  const simpleAppend = function (text) {
    for (const { sb } of recorders) {
      sb.push(text)
    }
  }

  saxParser.ontext = text => simpleAppend(escapeXml(text))

  saxParser.oncomment = comment => simpleAppend(`<!--${comment}-->`)

  saxParser.onopencdata = () => simpleAppend('<![CDATA[')
  saxParser.oncdata = cdata => simpleAppend(escapeXml(cdata))
  saxParser.onclosecdata = () => simpleAppend(']]>')
}

module.exports = {
  scanXML,
  looseTagEq
}
