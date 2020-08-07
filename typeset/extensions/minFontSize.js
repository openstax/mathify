const mj = MathJax // eslint-disable-line no-undef

mj.Hub.Register.StartupHook('mml Jax Ready', function () {
  const MML = mj.ElementJax.mml
  const math = MML.math.prototype.defaults
  const mstyle = MML.mstyle.prototype.defaults
  math.scriptminsize = mstyle.scriptminsize = 0.85
})

mj.Ajax.loadComplete('[extensions]/minFontSize.js')
