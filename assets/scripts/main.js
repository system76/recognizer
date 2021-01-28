import { Socket } from 'phoenix'
import LiveSocket from 'phoenix_live_view'
import topbar from 'topbar'

import 'phoenix_html/priv/static/phoenix_html.js'

import '../styles/main.scss'

const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content')
const liveSocket = new LiveSocket('/live', Socket, {
  params: {
    _csrf_token: csrfToken
  }
})

topbar.config({barColors: {0: '#63b1bc'}})
window.addEventListener('phx:page-loading-start', info => topbar.show())
window.addEventListener('phx:page-loading-stop', info => topbar.hide())

liveSocket.connect()

// Expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
// The latency simulator is enabled for the duration of the browser session.
// Call disableLatencySim() to disable:
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

function documentReady (fn) {
  if (document.readyState === 'complete' || document.readyState === 'interactive') {
    setTimeout(fn, 1)
  } else {
    document.addEventListener('DOMContentLoaded', fn)
  }
}

function toggleDisplay (selector, value) {
  const input = document.querySelector(selector)
  input.style.display = (value) ? 'block' : 'none'
}

documentReady(function () {
  document
  .querySelectorAll('input[name="user[type]"]')
  .forEach((field) => {
    field.addEventListener('change', (e) => {
      toggleDisplay('div.company_name', (e.target.value === 'business'))
    })
  })
})
