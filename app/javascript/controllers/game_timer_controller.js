import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "countdown" ]
  static values = { time: {type: Number, default: 30 }, offset: {type: Number, default: 0} }

  connect() {
    console.log("It has been connected to game timer")
    this.resetAndStartTimer()
  }

  disconnect() {
    console.log("It has been disconnected from game timer")
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
    }, 1000)
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
    this.timeValue-=1;
  }

  showTimeLeft() {
    this.countdownTarget.textContent=this.timeValue.toString()
  }
}