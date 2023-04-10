// Pipe And Replace Arbitrary Stuff
function PARAS (replacements, input, output) {
  let lineNumber = 0
  const spillover = []
  let replaceTo
  let finished = false

  function onLine (line) {
    let lastEndCol = 0
    // If the line started in the last chunk, concat here!
    if (spillover.length) {
      line = spillover.join('') + line
      spillover.splice(0)
    }
    if (finished) {
      output.write(line)
      return
    }
    // Handle multiline replacements
    if (replaceTo !== undefined) {
      if (lineNumber !== replaceTo[0]) return
      lastEndCol = replaceTo[1] - 1
      replaceTo = undefined
      // If there are no more replacements on this line
      if (replacements.length === 0 || replacements[0].posStart[0] !== lineNumber) {
        output.write(line.slice(lastEndCol))
        finished = replacements.length === 0
        return
      }
    } else if (replacements.length === 0) {
      output.write(line)
      finished = true
      return
    }
    if (replacements[0].posStart[0] === lineNumber) {
      while (true) {
        const replacement = replacements.shift()
        output.write(line.slice(lastEndCol, replacement.posStart[1] - 1))
        output.write(replacement.chunk)
        // We cannot do any more now
        if (replacement.posEnd[0] > lineNumber) {
          replaceTo = replacement.posEnd
          // Note: might want to throw error if there are still replacements
          // to be made on this line (that is unexpected)
          break
        }
        // If there is still stuff to replace, continue looping, else write
        // the rest of the line and break
        if (replacements.length && replacements[0].posStart[0] === lineNumber) {
          lastEndCol = replacement.posEnd[1] - 1
        } else {
          output.write(line.slice(replacement.posEnd[1] - 1))
          break
        }
      }
    } else {
      output.write(line)
    }
  }

  input.on('data', chunk => {
    let lineStartIdx = 0
    let i = 0
    for (; i < chunk.length; i++) {
      if (chunk[i] === '\n') {
        lineNumber++
        onLine(chunk.slice(lineStartIdx, i + 1))
        lineStartIdx = i + 1
      }
    }
    if (!chunk.endsWith('\n')) {
      spillover.push(chunk.slice(lineStartIdx))
    }
  })

  input.on('end', () => {
    lineNumber++
    onLine('')
  })
}

module.exports = {
  PARAS
}
