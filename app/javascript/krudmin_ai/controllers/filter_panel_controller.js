import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "trigger"]

  connect() {
    this.sync(this.panelTarget.hidden)
  }

  toggle() {
    this.panelTarget.hidden = !this.panelTarget.hidden
    this.sync(this.panelTarget.hidden)

    if (!this.panelTarget.hidden) this.panelTarget.querySelector("input, select, textarea, button")?.focus()
  }

  sync(hidden) {
    this.triggerTarget.setAttribute("aria-expanded", String(!hidden))
  }
}