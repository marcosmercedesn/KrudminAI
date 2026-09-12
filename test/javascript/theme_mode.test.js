import test from "node:test"
import assert from "node:assert/strict"
import { normalizeThemeMode, resolveTheme } from "../../app/javascript/krudmin_ai/theme_mode.js"

test("resolves explicit light and dark modes without reading system preference", () => {
  assert.equal(resolveTheme("light", true), "light")
  assert.equal(resolveTheme("dark", false), "dark")
})

test("resolves system mode using the supplied preference", () => {
  assert.equal(resolveTheme("system", true), "dark")
  assert.equal(resolveTheme("system", false), "light")
})

test("normalizes invalid persisted values to system mode", () => {
  assert.equal(normalizeThemeMode("unexpected"), "system")
  assert.equal(normalizeThemeMode("dark"), "dark")
})