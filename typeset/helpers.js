function assertTrue (condition, message) {
  if (!condition) {
    throw new Error(message)
  }
}

module.exports = { assertTrue }
