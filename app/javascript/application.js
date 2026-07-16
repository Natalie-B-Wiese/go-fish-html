import '@hotwired/turbo-rails'
import './controllers'

document.addEventListener('turbo:morph', (event) => {
  // Reconnect Stimulus controllers after morphing
  window.Stimulus.controllers.forEach(controller => {
    controller.disconnect()
    controller.connect()
  })
})