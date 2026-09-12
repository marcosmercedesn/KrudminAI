export const THEME_STORAGE_KEY = "krudmin-ai-theme"
export const THEME_MODES = ["light", "dark", "system"]

export function resolveTheme(mode, prefersDark) {
  if (mode === "dark") return "dark"
  if (mode === "light") return "light"

  return prefersDark ? "dark" : "light"
}

export function normalizeThemeMode(mode) {
  return THEME_MODES.includes(mode) ? mode : "system"
}