import '../../deps/phoenix_html/priv/static/phoenix_html.js'
import './util.js'

import '../styles/main.scss'

function documentReady (fn) {
  if (document.readyState === 'complete' || document.readyState === 'interactive') {
    setTimeout(fn, 1)
  } else {
    document.addEventListener('DOMContentLoaded', fn)
  }
}

function toggleDisplay (selector) {
  const input = document.querySelector(selector)
  input.classList.toggle('hidden')
}

documentReady(function () {
  document
  .querySelectorAll('input[name="user[type]"]')
  .forEach((field) => {
    field.addEventListener('change', (e) => {
      toggleDisplay('div.company_name')
    })
  })

  document
  .querySelectorAll('#copy-text')
  .forEach((field) => {
    field.addEventListener('click', (event) => {
      const text = event.target.dataset.recoveryBlock
      copyClipboard(text)
    })
  })
})
