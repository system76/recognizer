import '../styles/main.scss'

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
