import '@hotwired/turbo-rails'
import './controllers'

document.addEventListener('turbo:morph', (event) => {
  // Reconnect Stimulus controllers after morphing
  window.Stimulus.controllers.forEach(controller => {
    controller.disconnect()
    controller.connect()
  })
})

document.addEventListener('turbo:frame-missing', (event) => {
  if (event.target.id === 'modal') {
    event.preventDefault()

    event.detail.visit(event.detail.response.url, { action: 'replace' })
  }
})