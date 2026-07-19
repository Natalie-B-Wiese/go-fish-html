// https://blog.codeminer42.com/everything-you-need-to-ace-pwas/
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  connect() {		
    window.addEventListener('online', this.updateStatus.bind(this))
    window.addEventListener('offline', this.updateStatus.bind(this))
  }

  disconnect() {
    window.removeEventListener('online', this.updateStatus.bind(this))
    window.removeEventListener('offline', this.updateStatus.bind(this))
  }

  updateStatus() {
    this.element.classList.toggle('hidden', navigator.onLine)
  }
}