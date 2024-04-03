const { EventEmitter } = require("events")

const { DOMParser } = require('@xmldom/xmldom')

class ParseError extends Error { }

function parseXML (xmlString, options) {
  const { warn = console.warn, mimeType = 'text/xml' } = options
  const locator = { lineNumber: 0, columnNumber: 0 }
  const cb = () => {
    const pos = {
      line: locator.lineNumber - 1,
      character: locator.columnNumber - 1
    }
    throw new ParseError(`ParseError: ${JSON.stringify(pos)}`)
  }
  const p = new DOMParser({
    locator,
    errorHandler: {
      warning: warn,
      error: cb,
      fatalError: cb
    }
  })
  const doc = p.parseFromString(xmlString, mimeType)
  return doc
}

class MemoryStream extends EventEmitter {
  setEncoding (encoding) {
    if (encoding !== 'utf8' && encoding !== 'utf-8') {
      throw new Error('Memory stream only supported utf-8 encoding')
    }
    return this;
  }
}

class MemoryReadStream extends MemoryStream {
  constructor (content, chunkSize = 1<<20) {
    super()
    this.content = content
    this.chunkSize = chunkSize
  }

  on (evt, callback) {
    super.on(evt, callback)
    if (evt === 'data') {
      this._start()
    }
  }

  _start () {
    const content = this.content
    const chunkSize = this.chunkSize
    
    process.nextTick(() => {
      let offset = 0
      const chunks = Math.ceil(content.length / chunkSize)
      try {
        for (let i = 0; i < chunks; i++) {
          this.emit('data', content.slice(offset, offset + chunkSize))
          offset += chunkSize
        }
      } catch (err) {
        this.emit('error', err)
      } finally {
        this.emit('end')
      }
    });
    return this
  }
}

class MemoryWriteStream extends MemoryStream {
  constructor () {
    super()
    this.sb = []
  }

  write (chunk) {
    try {
      this.sb.push(chunk)
    } catch (err) {
      this.emit('error', err)
    }
  }

  end () {
    this.emit('finish', {});
  }

  getValue () {
    return this.sb.join('')
  }
}

async function walkJSON (content, handler) {
  const recurse = async (name, value, parent, prevPath) => {
    const fqPath = [...prevPath, name]
    const jsType = typeof value
    switch (jsType) {
      case 'string':
      case 'number':
      case 'boolean':
        await handler({ name, fqPath, value, parent, type: jsType })
        return
      case 'object': {
        const type = Array.isArray(value) ? 'array' : 'object'
        await handler({ name, fqPath, value, parent, type })
        if (value != null) {
          for (const [k, v] of Object.entries(value)) {
            await recurse(k, v, value, fqPath)
          }
        }
      }
    }
  }
  await recurse('', content, undefined, [])
}

module.exports = {
  MemoryReadStream,
  MemoryWriteStream,
  walkJSON,
  parseXML,
}

