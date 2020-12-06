const path = require('path')
const purgecss = require('@fullhuman/postcss-purgecss')

module.exports = {
  plugins: [
    purgecss({
      content: [
        path.resolve(__dirname, '../lib/recognizer_web/templates/**/*.html.eex')
      ]
    })
  ]
}
