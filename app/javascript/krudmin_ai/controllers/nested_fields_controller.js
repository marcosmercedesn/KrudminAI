import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["addButton", "destroyInput", "row", "rows", "template"]
  static values = { maximum: Number }

  connect() {
    this.nextIdentifier = this.rowTargets.length
    this.syncAddButton()
  }

  add() {
    if (this.visibleRows().length >= this.maximumValue) return

    const identifier = String(this.nextIdentifier++)
    this.rowsTarget.insertAdjacentHTML("beforeend", this.templateTarget.innerHTML.replaceAll("NEW_RECORD", identifier))
    this.syncAddButton()
  }

  remove(event) {
    const row = event.currentTarget.closest("[data-krudmin-ai-nested-fields-target~='row']")
    if (row.dataset.persisted === "true") {
      row.querySelector("[data-krudmin-ai-nested-fields-target~='destroyInput']").value = "1"
      row.hidden = true
    } else {
      row.remove()
    }
    this.syncAddButton()
  }

  visibleRows() {
    return this.rowTargets.filter((row) => !row.hidden)
  }

  syncAddButton() {
    this.addButtonTarget.disabled = this.visibleRows().length >= this.maximumValue
  }
}