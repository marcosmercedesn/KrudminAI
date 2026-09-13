import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "trigger"]

  connect() {
    this.sync(this.panelTarget.hidden)
    this.panelTarget.classList.toggle("is-open", !this.panelTarget.hidden)
  }

  toggle() {
    if (this.panelTarget.hidden) {
      this.panelTarget.hidden = false
      requestAnimationFrame(() => this.panelTarget.classList.add("is-open"))
      this.sync(false)
      this.panelTarget.querySelector("input, select, textarea, button")?.focus()
      return
    }

    this.panelTarget.classList.remove("is-open")
    this.sync(true)
    this.panelTarget.addEventListener("transitionend", () => {
      if (!this.panelTarget.classList.contains("is-open")) this.panelTarget.hidden = true
    }, { once: true })
  }

  sync(hidden) {
    this.triggerTarget.setAttribute("aria-expanded", String(!hidden))
  }
}