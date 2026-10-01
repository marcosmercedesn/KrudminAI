import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["addButton", "destroyInput", "row", "rows", "template"]
  static values = { maximum: Number, sortable: String }

  connect() {
    this.nextIdentifier = this.rowTargets.length
    this.syncAddButton()
    this.syncMoveButtons()
  }

  add() {
    if (this.visibleRows().length >= this.maximumValue) return

    const identifier = String(this.nextIdentifier++)
    this.rowsTarget.insertAdjacentHTML("beforeend", this.templateTarget.innerHTML.replaceAll("NEW_RECORD", identifier))
    this.renumber()
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
    this.renumber()
    this.syncAddButton()
  }

  moveUp(event) {
    const row = event.currentTarget.closest("[data-krudmin-ai-nested-fields-target~='row']")
    const previous = this.visibleRows()[this.visibleRows().indexOf(row) - 1]
    if (previous) this.move(row, previous)
  }

  moveDown(event) {
    const row = event.currentTarget.closest("[data-krudmin-ai-nested-fields-target~='row']")
    const next = this.visibleRows()[this.visibleRows().indexOf(row) + 1]
    if (next) this.move(row, next.nextSibling)
  }

  move(row, before) {
    this.rowsTarget.insertBefore(row, before)
    this.renumber()
    row.querySelector("[data-action*='moveUp']")?.focus()
  }

  dragStart(event) {
    this.draggedRow = event.currentTarget.closest("[data-krudmin-ai-nested-fields-target~='row']")
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", "reorder")
    const bounds = this.draggedRow.getBoundingClientRect()
    event.dataTransfer.setDragImage(this.draggedRow, event.clientX - bounds.left, event.clientY - bounds.top)
    requestAnimationFrame(() => {
      if (this.draggedRow) this.draggedRow.classList.add("is-dragging")
    })
  }

  dragOver(event) {
    if (!this.draggedRow) return

    const target = event.target.closest("[data-krudmin-ai-nested-fields-target~='row']")
    this.clearDropMarkers()
    if (!this.visibleRows().includes(target)) return

    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
    if (target !== this.draggedRow) {
      const after = this.visibleRows().indexOf(this.draggedRow) < this.visibleRows().indexOf(target)
      target.classList.add(after ? "is-drop-after" : "is-drop-before")
    }
  }

  drop(event) {
    const target = event.target.closest("[data-krudmin-ai-nested-fields-target~='row']")
    if (!this.draggedRow || !this.visibleRows().includes(target) || target === this.draggedRow) return

    event.preventDefault()
    const after = this.visibleRows().indexOf(this.draggedRow) < this.visibleRows().indexOf(target)
    this.rowsTarget.insertBefore(this.draggedRow, after ? target.nextSibling : target)
    this.renumber()
    this.dragEnd()
  }

  dragEnd() {
    this.draggedRow?.classList.remove("is-dragging")
    this.clearDropMarkers()
    this.draggedRow = null
  }

  clearDropMarkers() {
    this.rowTargets.forEach((row) => row.classList.remove("is-drop-before", "is-drop-after"))
  }

  renumber() {
    if (!this.sortableValue) return

    this.visibleRows().forEach((row, index) => {
      const field = [...row.querySelectorAll("[data-krudmin-ai-validation-field]")].find((element) => element.dataset.krudminAiValidationField === this.sortableValue)
      const input = field?.querySelector("input")
      if (input && !input.disabled) {
        input.value = String(index + 1)
        input.dispatchEvent(new Event("input", { bubbles: true }))
      }
    })
    this.syncMoveButtons()
  }

  syncMoveButtons() {
    const rows = this.visibleRows()
    rows.forEach((row, index) => {
      const up = row.querySelector("[data-action*='moveUp']")
      const down = row.querySelector("[data-action*='moveDown']")
      if (up) up.disabled = index === 0
      if (down) down.disabled = index === rows.length - 1
    })
  }

  visibleRows() {
    return this.rowTargets.filter((row) => !row.hidden)
  }

  syncAddButton() {
    this.addButtonTarget.disabled = this.visibleRows().length >= this.maximumValue
  }
}