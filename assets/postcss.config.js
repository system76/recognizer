const path = require('path')
const purgecss = require('@fullhuman/postcss-purgecss')

module.exports = (options) => {
  const devMode = options.mode !== 'production'

  return {
    plugins: [
      ...(devMode ? [] : [purgecss({
        content: [
          path.resolve(__dirname, '../lib/recognizer_web/templates/**/*.html.eex'),
          path.resolve(__dirname, '../lib/recognizer_web/views/**/*.ex')
        ]
      })])
    ]
  }
}
