import { Controller } from "@hotwired/stimulus"
import { parseRules, validateValue } from "krudmin_ai/validation/rules"

const FIELD_SELECTOR = "[data-krudmin-ai-validation-field]"
const ERROR_SELECTOR = "[data-krudmin-ai-validation-error]"
const VALUE_SELECTOR = "[data-krudmin-ai-validation-control]"
const FOCUS_SELECTOR = "[data-krudmin-ai-validation-focus]"
const NATIVE_SELECTOR = "input:not([type='hidden']), select, textarea"

export default class extends Controller {
  static targets = [ "summary", "summaryList" ]

  connect() {
    this.element.noValidate = true
    this.touched = new WeakSet()
    this.listeners = [
      [ "focusout", this.revalidate.bind(this) ],
      [ "change", this.revalidate.bind(this) ],
      [ "input", this.refresh.bind(this) ],
      [ "submit", this.validateSubmission.bind(this) ]
    ]
    this.listeners.forEach(([ name, handler ]) => this.element.addEventListener(name, handler))
  }

  disconnect() {
    this.element.noValidate = false
    this.listeners.forEach(([ name, handler ]) => this.element.removeEventListener(name, handler))
  }

  revalidate(event) {
    const field = this.fieldFor(event.target)
    if (!field) return

    this.touched.add(field)
    this.apply(field, this.failuresFor(field))
  }

  // While typing, only a field already showing a problem is re-checked.
  refresh(event) {
    const field = this.fieldFor(event.target)
    if (!field || !this.touched.has(field)) return
    if (this.errorNode(field)?.hidden !== false) return

    this.apply(field, this.failuresFor(field))
  }

  validateSubmission(event) {
    const invalid = []
    this.fields().forEach((field) => {
      this.touched.add(field)
      const failures = this.failuresFor(field)
      this.apply(field, failures)
      if (failures.length > 0) invalid.push({ field, failures })
    })

    if (invalid.length === 0) return

    event.preventDefault()
    this.renderSummary(invalid)
    this.reveal(invalid[0].field)
  }

  apply(field, failures) {
    const node = this.errorNode(field)
    if (!node) return

    node.replaceChildren(...failures.map((failure) => this.messageElement(field, failure)))
    node.hidden = failures.length === 0
    field.classList.toggle("is-invalid", failures.length > 0)
    this.focusControlFor(field)?.setAttribute("aria-invalid", String(failures.length > 0))
  }

  // Server errors are replaced rather than preserved, so a submission is never blocked by a
  // stale server decision the client cannot reproduce.
  failuresFor(field) {
    const control = this.controlFor(field)
    if (!control || this.skip(field, control)) return []

    const rules = parseRules(field.dataset.krudminAiValidationRules)
    if (Object.keys(rules).length === 0) return []

    return validateValue(rules, this.valueOf(control), { confirmation: this.confirmationValue(rules.confirms) })
  }

  messageElement(field, failure) {
    const span = document.createElement("span")
    span.textContent = failure.message ?? this.controlFor(field)?.validationMessage ?? ""

    return span
  }

  skip(field, control) {
    return control.disabled || field.closest("[hidden]") !== null
  }
  valueOf(control) {
    if (control.type === "checkbox") return control.checked ? control.value : ""
    if (control.multiple && control.selectedOptions) return Array.from(control.selectedOptions, (option) => option.value)

    return control.value
  }

  confirmationValue(attribute) {
    if (!attribute) return ""

    return this.element.querySelector(`[name$="[${attribute}]"]`)?.value ?? ""
  }

  // A remote lookup keeps its authoritative value in a hidden input while the user types in a
  // separate combobox, so the value and the focus target are not always the same element.
  controlFor(field) {
    return field.querySelector(VALUE_SELECTOR) ?? field.querySelector(NATIVE_SELECTOR) ?? field.querySelector("input[type='hidden']")
  }

  focusControlFor(field) {
    return field.querySelector(FOCUS_SELECTOR) ?? field.querySelector(NATIVE_SELECTOR) ?? this.controlFor(field)
  }

  errorNode(field) {
    return field.querySelector(ERROR_SELECTOR)
  }

  fieldFor(node) {
    return node instanceof Element ? node.closest(FIELD_SELECTOR) : null
  }

  fields() {
    return Array.from(this.element.querySelectorAll(FIELD_SELECTOR))
  }

  renderSummary(invalid) {
    if (!this.hasSummaryTarget || !this.hasSummaryListTarget) return

    this.summaryListTarget.replaceChildren(...invalid.map((entry) => this.summaryItem(entry)))
    this.summaryTarget.hidden = false
  }

  summaryItem({ field, failures }) {
    const item = document.createElement("li")
    const control = this.focusControlFor(field)
    const message = failures[0].message ?? control?.validationMessage ?? ""

    if (control?.id) {
      const link = document.createElement("a")
      link.href = `#${control.id}`
      link.textContent = message
      item.appendChild(link)
    } else {
      item.textContent = message
    }

    return item
  }

  reveal(field) {
    const control = this.focusControlFor(field)
    if (!control) return

    for (let ancestor = field.parentElement; ancestor; ancestor = ancestor.parentElement) {
      if (ancestor.hidden) ancestor.hidden = false
      if (ancestor instanceof HTMLDetailsElement) ancestor.open = true
    }

    const reduced = window.matchMedia?.("(prefers-reduced-motion: reduce)")?.matches
    field.scrollIntoView({ behavior: reduced ? "auto" : "smooth", block: "center" })
    control.focus({ preventScroll: true })
  }
}
