import { Socket } from 'phoenix'
import LiveSocket from 'phoenix_live_view'
import topbar from 'topbar'

import 'alpinejs'
import 'phoenix_html/priv/static/phoenix_html.js'

const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content')
const liveSocket = new LiveSocket('/live', Socket, {
  params: {
    _csrf_token: csrfToken
  }
})

topbar.config({barColors: {0: '#63b1bc'}, shadowBlur: 0})
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
