import { Controller } from "@hotwired/stimulus"
import { normalizeThemeMode, resolveTheme, THEME_STORAGE_KEY } from "krudmin_ai/theme_mode"

export default class extends Controller {
  static values = { mode: String }

  connect() {
    this.mediaQuery = window.matchMedia("(prefers-color-scheme: dark)")
    this.handleSystemChange = this.handleSystemChange.bind(this)
    this.mediaQuery.addEventListener("change", this.handleSystemChange)
    this.apply(this.initialMode())
  }

  disconnect() {
    this.mediaQuery?.removeEventListener("change", this.handleSystemChange)
  }

  select(event) {
    this.apply(event.currentTarget.value)
  }

  apply(mode) {
    this.mode = normalizeThemeMode(mode)
    document.documentElement.dataset.theme = resolveTheme(this.mode, this.mediaQuery.matches)
    document.documentElement.dataset.themeMode = this.mode
    window.localStorage.setItem(THEME_STORAGE_KEY, this.mode)
  }

  handleSystemChange() {
    if (this.mode === "system") this.apply("system")
  }

  initialMode() {
    return this.hasModeValue ? this.modeValue : window.localStorage.getItem(THEME_STORAGE_KEY)
  }
}