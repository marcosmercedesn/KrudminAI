import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "value", "listbox", "status"]
  static values = { url: String, minimum: Number }

  connect() {
    this.abortController = null
    this.timer = null
    this.activeIndex = -1
    this.results = []
    this.query = ""
    this.page = 1
  }

  disconnect() {
    this.abortController?.abort()
    clearTimeout(this.timer)
  }

  search() {
    clearTimeout(this.timer)
    const query = this.inputTarget.value.trim()
    if (query.length < this.minimumValue) return this.render([], "")

    this.timer = setTimeout(() => this.fetch(query), 250)
  }

  keydown(event) {
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault()
      this.activeIndex = Math.max(0, Math.min(this.results.length - 1, this.activeIndex + (event.key === "ArrowDown" ? 1 : -1)))
      this.syncActive()
    } else if (event.key === "Enter" && this.activeIndex >= 0) {
      event.preventDefault()
      this.select(this.results[this.activeIndex])
    } else if (event.key === "Escape") {
      this.render([], "")
    }
  }

  choose(event) {
    this.select(this.results.find((result) => String(result.id) === event.currentTarget.dataset.id))
  }

  more() {
    this.fetch(this.query, this.page + 1, true)
  }

  async fetch(query, page = 1, append = false) {
    this.abortController?.abort()
    this.abortController = new AbortController()
    this.inputTarget.setAttribute("aria-busy", "true")
    this.statusTarget.textContent = "Loading results"
    try {
      const response = await window.fetch(`${this.urlValue}?q=${encodeURIComponent(query)}&page=${page}`, { signal: this.abortController.signal, headers: { Accept: "application/json" } })
      if (!response.ok) throw new Error("Lookup failed")
      const payload = await response.json()
      this.query = query
      this.page = page
      this.render(append ? this.results.concat(payload.results || []) : (payload.results || []), payload.results?.length ? `${payload.results.length} results available` : "No results", payload.more)
    } catch (error) {
      if (error.name !== "AbortError") this.render([], "Lookup unavailable")
    } finally {
      this.inputTarget.removeAttribute("aria-busy")
    }
  }

  select(result) {
    if (!result) return
    this.valueTarget.value = result.id
    this.inputTarget.value = result.label
    this.valueTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.render([], `${result.label} selected`)
  }

  render(results, message, more = false) {
    this.results = results
    this.activeIndex = -1
    const options = results.map((result, index) => {
      const option = document.createElement("button")
      option.type = "button"
      option.id = `${this.listboxTarget.id}-option-${index}`
      option.role = "option"
      option.dataset.id = result.id
      option.textContent = result.label
      option.addEventListener("click", (event) => this.choose(event))
      return option
    })
    if (more) {
      const moreButton = document.createElement("button")
      moreButton.type = "button"
      moreButton.textContent = "More results"
      moreButton.addEventListener("click", () => this.more())
      options.push(moreButton)
    }
    this.listboxTarget.replaceChildren(...options)
    this.listboxTarget.hidden = results.length === 0
    this.inputTarget.setAttribute("aria-expanded", String(results.length > 0))
    this.statusTarget.textContent = message
  }

  syncActive() {
    const option = this.listboxTarget.children[this.activeIndex]
    if (!option) return
    this.inputTarget.setAttribute("aria-activedescendant", option.id)
    Array.from(this.listboxTarget.children).forEach((item, index) => item.setAttribute("aria-selected", String(index === this.activeIndex)))
  }
}