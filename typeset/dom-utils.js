const { DOMParser } = require('@xmldom/xmldom');

const ELEMENT_NODE = 1;

function getParentElement(node) {
  let ptr = node.parentNode;
  while (ptr && ptr.nodeType !== ELEMENT_NODE) {
    ptr = ptr.parentNode;
  }
  return ptr;
}

function* ancestorOrSelf(node) {
  let ptr = node;
  while (ptr) {
    yield ptr;
    ptr = getParentElement(ptr);    
  }
}

class ParseError extends Error { }

function parseXML(xmlString, mimetype) {
  const locator = { lineNumber: 0, columnNumber: 0 }
  const cb = /* istanbul ignore next */ () => {
    const pos = {
      line: locator.lineNumber - 1,
      character: locator.columnNumber - 1
    }
    throw new ParseError(`ParseError: ${JSON.stringify(pos)}`)
  }
  const p = new DOMParser({
    locator,
    errorHandler: {
      warning: console.warn,
      error: cb,
      fatalError: cb
    }
  })
  const doc = p.parseFromString(xmlString, mimetype)
  return doc
}

module.exports = { ancestorOrSelf, getParentElement, ParseError, parseXML };
