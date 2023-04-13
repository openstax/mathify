/*
1.
2. If there is a multiline replacement and more replacements on this line
3. If there is a multiline replacement and no additional replacements on this line
4. If there is a multiline replacement and no additional replacements
5. If there are no additional replacements
6. If there are multiple replacements on this line
7. If the current replacement extends past this line
8. If there are more replacements, but none on this line
*/

function expectValue (v, msg = 'Expected a value but got nothing') {
  if (v == null) {
    throw new Error(msg)
  }
  return v
}

// Pipe And Replace Arbitrary Stuff
function PARAS (replacements, input, output) {
  let lineNumber = 0
  const spillover = []
  let replaceTo
  let finished = false

  function handleLine (line) {
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
        output.write(expectValue(replacement.substitution))
        // We cannot do any more now
        if (replacement.posEnd[0] > lineNumber) {
          replaceTo = replacement.posEnd
          // When there are replacements that fall between this one and its end line,
          // they are implicitly replaced. Just remove them from the list.
          while (replacements.length && replacements[0].posStart[0] < replaceTo[0]) {
            replacements.shift()
          }
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
    for (let i = 0; i < chunk.length; i++) {
      if (chunk[i] === '\n') {
        lineNumber++
        handleLine(chunk.slice(lineStartIdx, i + 1))
        lineStartIdx = i + 1
      }
    }
    if (!chunk.endsWith('\n')) {
      spillover.push(chunk.slice(lineStartIdx))
    }
  })

  input.on('end', () => {
    lineNumber++
    handleLine('')
    output.end()
  })
}

module.exports = {
  PARAS
}
