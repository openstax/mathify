const { EventEmitter } = require('node:events')

const mmlPattern = /^\s*<(\w+:)?math/

const mergeByIndex = (lhs, rhs, options) => {
  return Object.values(
    recursiveMerge(
      Object.fromEntries(Object.entries(lhs)),
      Object.fromEntries(Object.entries(rhs)),
      options
    )
  )
}

const defaultValueMerge = (lhs, rhs) => {
  return rhs ?? lhs
}

const recursiveMerge = (lhs, rhs, options) => {
  const { arrayMerge = mergeByIndex, customMerge = defaultValueMerge } =
    options ?? {}
  if (
    typeof lhs === 'object' &&
    typeof rhs === 'object' &&
    lhs != null &&
    rhs != null
  ) {
    const isArrayL = Array.isArray(lhs)
    const isArrayR = Array.isArray(rhs)
    if (isArrayL || isArrayR) {
      if (!(isArrayL && isArrayR)) throw new Error('Expected two arrays')
      return arrayMerge(lhs, rhs, options)
    } else {
      const keysL = Object.keys(lhs)
      const keysR = Object.keys(rhs)
      const sharedKeys = keysL.filter((k) => keysR.indexOf(k) !== -1)
      const merged = Object.fromEntries(
        sharedKeys.map((k) => [
          k,
          recursiveMerge(Reflect.get(lhs, k), Reflect.get(rhs, k), options)
        ])
      )
      return { ...lhs, ...rhs, ...merged }
    }
  } else {
    return customMerge(lhs, rhs, options)
  }
}

const filterNode = (adaptor, node, speech, braille, removeSemantics = true) => {
  // Skip text and comment nodes.
  if (adaptor.kind(node).startsWith('#')) return

  // Filter the attributes.
  const attributes = adaptor.allAttributes(node)
  for (const { name } of attributes || []) {
    // Save the speech and braille attributes (should be for the full expression).
    if (speech && name === 'data-semantic-speech-none') {
      speech.push(adaptor.getAttribute(node, name))
    }
    if (braille && name === 'data-semantic-braille') {
      braille.push(adaptor.getAttribute(node, name))
    }

    // Remove the latex and data-semantic attributes, if requested.
    if (
      removeSemantics &&
      name.match(/^(?:data-semantic-.*|data-speech-node|data-(?:speech|braille)-attached|aria-level)$/)
    ) adaptor.removeAttribute(node, name)
  }

  // Process the node's children
  for (const child of adaptor.childNodes(node) || []) {
    filterNode(adaptor, child, speech, braille, removeSemantics)
  }
}

const addSpeech = (adaptor, node, { speech, braille }) => {
  if (speech && speech.length > 0) {
    if (adaptor.kind(node) === 'svg') {
      const caption = adaptor.text(speech[0])
      const title = adaptor.create('title')
      adaptor.append(title, caption)
      adaptor.append(node, title)
    } else {
      adaptor.setAttribute(node, 'aria-label', speech[0])
    }
  }
  if (braille && braille.length > 0) {
    adaptor.setAttribute(node, 'aria-braillelabel', braille[0])
  }
  const children = adaptor.kind(node) === 'svg'
    ? [adaptor.getElement('[data-mml-node="math"]', node)]
    : adaptor.childNodes(node)
  for (const child of children.filter((c) => c !== undefined)) {
    if (adaptor.kind(child).charAt(0) !== '#') {
      adaptor.setAttribute(child, 'aria-hidden', 'true')
    }
  }
}

class JaxBase {
  constructor (lib, options) {
    this.mathJaxPath = options?.mathJaxPath ?? 'mathjax'
    this.lib = `${this.mathJaxPath}/${lib.replace(/(?<!\.js)$/, '.js')}`
    this.options = options ?? {}
    this.initialized = false
    this.errors = []
    this._hooks = new Map()
  }

  getHook (kind) {
    let hook = this._hooks.get(kind)
    if (!hook) {
      hook = []
      this._hooks.set(kind, hook)
    }
    return hook
  }

  addHook (kind, cb) {
    this.getHook(kind).push(cb)
  }

  runHook (kind, args) {
    this.getHook(kind).forEach((hook) => hook({ args }))
  }

  get config () {
    return {
      loader: {
        paths: {
          mathjax: this.mathJaxPath
        },
        load: this.options.load ?? ['adaptors/liteDOM'],
        require: (file) => require(file)
      },
      output: {
        linebreaks: {
          inline: true
        },
        font: 'mathjax-stix2'
      },
      tex: {
        formatError (_, error) {
          throw new Error(error.message)
        }
      },
      startup: {
        ready () {
          // https://github.com/mathjax/MathJax/issues/3185
          const { MmlMath } = MathJax._.core.MmlTree.MmlNodes.math
          const { MmlMstyle } = MathJax._.core.MmlTree.MmlNodes.mstyle
          MmlMath.defaults.scriptsizemultiplier = MmlMstyle.defaults.scriptsizemultiplier = 0.8

          MathJax.startup.defaultReady()
        }
      }
    }
  }

  async init () {
    if (!this.initialized) {
      this.initialized = true
      global.MathJax = this.config
      require(this.lib)
    }
    await MathJax.startup.promise
  }

  done () {
    MathJax.done()
  }

  get document () {
    return MathJax.startup.document
  }

  get adaptor () {
    return this.document.adaptor
  }

  handleError (err) {
    this.errors.push(err)
  }

  async convertMath (math, conversion, chunkSize) {
    const total = math.length
    const results = []
    const wrapper = async (item) => {
      try {
        return { math: await conversion(item) }
      } catch (e) {
        return { error: { message: e, source: item } }
      }
    }
    for (let i = 0; ; i += chunkSize) {
      const chunk = math.slice(i, chunkSize + i)
      if (chunk.length === 0) break
      this.runHook('progress', { from: i, to: i + chunk.length, total })
      results.push(...(await Promise.all(chunk.map(wrapper))))
    }
    return results
  }
}

class TexMmlToSvg extends JaxBase {
  constructor (options) {
    const optionsWithLoad = {
      load: ['adaptors/liteDOM', 'output/svg'],
      ...options
    }
    super('tex-mml-svg', optionsWithLoad)
    this.css = [
      'svg a{fill:blue;stroke:blue}',
      '[data-mml-node="merror"]>g{fill:red;stroke:red}',
      '[data-mml-node="merror"]>rect[data-background]{fill:yellow;stroke:none}',
      '[data-frame],[data-line]{stroke-width:70px;fill:none}',
      '.mjx-dashed{stroke-dasharray:140}',
      '.mjx-dotted{stroke-linecap:round;stroke-dasharray:0,140}',
      'use[data-c]{stroke-width:3px}'
    ]
  }

  get config () {
    return recursiveMerge(super.config, {
      options: {
        sre: {
          locale: this.options.locale ?? 'en',
          braille: this.options.braille ?? 'nemeth'
        }
      },
      svg: {
        fontCache: 'local',
        blacker: 0,
        scale: 1.15
      }
    })
  }

  async convert (math, chunkSize = 3000) {
    const { adaptor, css } = this
    const options = this.options.typesetOptions ?? {}
    const doConvert = async (item) => {
      const speech = []
      const braille = []
      const isMml = mmlPattern.test(item)
      const node = isMml
        ? await MathJax.mathml2svgPromise(item, options)
        : await MathJax.tex2svgPromise(item, options)
      const svg = adaptor.getElement('svg', node)
      filterNode(adaptor, node, speech, braille)
      // Special case for empty mtr breaking table speech generation
      if (speech.length === 0 && isMml) {
        const parsed = adaptor.parse(item)
        const toRemove = []
        let mathNode
        const filterMath = (node) => {
          const { kind, children } = node
          if (mathNode === undefined && kind.endsWith('math')) mathNode = node
          if (Array.isArray(children) && children.length > 0) children.forEach(filterMath)
          else if (kind.endsWith('mtr')) toRemove.push(node)
        }
        filterMath(parsed.body)
        toRemove.forEach(adaptor.remove.bind(adaptor))
        if (mathNode) {
          const speechReadyItem = adaptor.outerHTML(mathNode)
          const speechNode = await MathJax.mathml2svgPromise(speechReadyItem, options)
          filterNode(adaptor, speechNode, speech, braille)
        }
      }
      if (speech.length === 0) {
        this.runHook('diagnostic', { type: 'no_speech', source: item })
        speech.push('Nondescript Math')
      }
      // TODO: Kinda weird to replicate the same speech to all of these.
      adaptor.tags(node, 'svg').forEach((svg) => {
        addSpeech(adaptor, svg, { speech, braille })
      })
      return adaptor.outerHTML(node)
        .replace('<defs>', `<defs>\n<style>${css.join('')}</style>`)
    }
    return await this.convertMath(math, doConvert, chunkSize)
  }
}

class TexToMml extends JaxBase {
  constructor (options) {
    const optionsWithLoad = {
      load: ['adaptors/liteDOM', 'input/tex'],
      ...options
    }
    super('startup', optionsWithLoad)
  }

  async convert (math, chunkSize = 3000) {
    const options = this.options.typesetOptions ?? {}
    const doConvert = async (item) => {
      return await MathJax.tex2mmlPromise(item, options)
    }
    return await this.convertMath(math, doConvert, chunkSize)
  }
}

module.exports = { TexToMml, TexMmlToSvg }
