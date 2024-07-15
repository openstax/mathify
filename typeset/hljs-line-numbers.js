const TABLE_NAME = 'hljs-ln'
const LINE_NAME = 'hljs-ln-line'
const CODE_BLOCK_NAME = 'hljs-ln-code'
const NUMBERS_BLOCK_NAME = 'hljs-ln-numbers'
const NUMBER_LINE_NAME = 'hljs-ln-n'
const DATA_ATTR_NAME = 'data-line-number'
const BREAK_LINE_REGEXP = /\r\n|\r|\n/g

function format (format, args) {
  return format.replace(/\{(\d+)\}/g, function (m, n) {
    return args[n] !== undefined ? args[n] : m
  })
}

function addCodeLineNumbers (inputHtml) {
  var lines = getLines(inputHtml.trim())
  // if last line contains only carriage return remove it
  if (lines.length == 0) {
    return inputHtml
  }

  if (lines[lines.length - 1].trim() === '') {
    lines.pop()
  }

  var html = ''
  for (var i = 0, l = lines.length; i < l; i++) {
    html += format(
      '<tr>' +
                '<td class="{0} {1}" {3}="{5}">' +
                    '<div class="{2}" {3}="{5}">{5}</div>' +
                '</td>' +
                '<td class="{0} {4}" {3}="{5}">' +
                    '{6}' +
                '</td>' +
            '</tr>',
      [
        LINE_NAME,
        NUMBERS_BLOCK_NAME,
        NUMBER_LINE_NAME,
        DATA_ATTR_NAME,
        CODE_BLOCK_NAME,
        i + 1,
        lines[i].length > 0 ? lines[i] : ' '
      ])
  }
  return format('<table class="{0}">{1}</table>', [TABLE_NAME, html])
}

function getLines (text) {
  if (text.length === 0) return []
  return text.split(BREAK_LINE_REGEXP)
}

module.exports = { addCodeLineNumbers }
