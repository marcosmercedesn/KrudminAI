import { Controller } from "@hotwired/stimulus"

const COLLAPSED_STORAGE_KEY = "krudmin-ai-sidebar-collapsed"

export default class extends Controller {
  static targets = ["backdrop", "panel", "toggle", "toggleLabel"]

  connect() {
    this.mediaQuery = window.matchMedia("(max-width: 70rem)")
    this.handleViewportChange = this.restore.bind(this)
    this.mediaQuery.addEventListener("change", this.handleViewportChange)
    this.restore()
  }

  disconnect() {
    this.mediaQuery?.removeEventListener("change", this.handleViewportChange)
  }

  toggle() {
    if (this.mobile()) {
      document.documentElement.dataset.sidebarOpen = String(!this.expanded())
    } else {
      const collapsed = this.expanded()
      document.documentElement.dataset.sidebarCollapsed = String(collapsed)
      window.localStorage.setItem(COLLAPSED_STORAGE_KEY, String(collapsed))
    }
    this.sync()
  }

  close() {
    if (!this.mobile()) return

    delete document.documentElement.dataset.sidebarOpen
    this.sync()
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close()
  }

  restore() {
    if (this.mobile()) {
      delete document.documentElement.dataset.sidebarCollapsed
      delete document.documentElement.dataset.sidebarOpen
    } else {
      document.documentElement.dataset.sidebarCollapsed = String(window.localStorage.getItem(COLLAPSED_STORAGE_KEY) === "true")
      delete document.documentElement.dataset.sidebarOpen
    }
    this.sync()
  }

  expanded() {
    return this.mobile() ? document.documentElement.dataset.sidebarOpen === "true" : document.documentElement.dataset.sidebarCollapsed !== "true"
  }

  mobile() {
    return this.mediaQuery.matches
  }

  sync() {
    const expanded = this.expanded()
    this.toggleTarget.setAttribute("aria-expanded", String(expanded))
    this.toggleTarget.setAttribute("aria-label", expanded ? "Collapse navigation" : "Open navigation")
    this.toggleLabelTarget.textContent = expanded ? "Collapse navigation" : "Open navigation"
  }
}