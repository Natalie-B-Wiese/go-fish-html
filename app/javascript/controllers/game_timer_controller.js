import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "countdown" ]
  static values = { time: {type: Number, default: 15 }, offset: {type: Number, default: 0} }

  connect() {
    this.resetAndStartTimer()
  }

  disconnect() {
    this.stopTimer()
  }

  resetAndStartTimer() {
    this.stopTimer()
    this.timeValue+=this.offsetValue
    this.startTimer()
  }

  startTimer() {
    // Set an interval and update every second (1000ms = 1 second)
    this.refreshTimer = setInterval(() => {
      this.decrementTimeLeft()
      if (this.timeValue<=0) this.outOfTime()
        
    }, 1000)
  }

  outOfTime()
  {
    this.dispatch('timer-over', {
      details: { autoPlay: true }
    })
    this.stopTimer()
  }

  stopTimer() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
  }

  timeValueChanged() {
    this.showTimeLeft()
  }

  decrementTimeLeft() {
    this.timeValue-=1
  }

  showTimeLeft() {
    this.countdownTarget.textContent=this.timeValue.toString()
  }
}