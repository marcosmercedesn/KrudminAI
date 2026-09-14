// Pure rule evaluation shared by the form validation controller. No DOM access.
// Every rule here is narrower than, or equal to, its server counterpart: when a value cannot
// be judged with certainty the rule is skipped and the server decides.

const WHATWG_EMAIL = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/
const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/
const ISO_TIME = /^\d{2}:\d{2}(:\d{2})?$/
const ISO_DATETIME = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2})?$/

export function parseRules(payload) {
  if (!payload) return {}

  try {
    const parsed = JSON.parse(payload)
    return parsed && typeof parsed === "object" ? parsed : {}
  } catch {
    return {}
  }
}

export function isBlank(value) {
  if (value === null || value === undefined) return true
  if (Array.isArray(value)) return value.length === 0

  return String(value).trim() === ""
}

export function validateValue(rules = {}, value, context = {}) {
  const failures = []
  const fail = (key) => failures.push({ key, message: rules.messages?.[key] ?? null })

  if (isBlank(value)) {
    if (rules.required) fail("required")

    // Every other rule is skipped on a blank value so the client never rejects
    // something the server would have accepted.
    return failures
  }

  const text = Array.isArray(value) ? "" : String(value)

  if (!Array.isArray(value)) {
    if (Number.isInteger(rules.is) && text.length !== rules.is) fail("is")
    if (Number.isInteger(rules.minimum) && text.length < rules.minimum) fail("minimum")
    if (Number.isInteger(rules.maximum) && text.length > rules.maximum) fail("maximum")
    if (rules.pattern && matchesPattern(rules.pattern, text) === false) fail("pattern")
  }

  if (Array.isArray(rules.one_of) && !includesValue(rules.one_of, value)) fail("one_of")
  if (Array.isArray(rules.none_of) && includesValue(rules.none_of, value)) fail("none_of")
  if (rules.confirms && text !== String(context.confirmation ?? "")) fail("confirms")

  collectNumericFailures(rules, text, fail)
  if (typeFailure(rules.type, text)) fail("type")

  return failures
}

function collectNumericFailures(rules, text, fail) {
  if (!rules.numeric) return

  const number = Number(text)
  if (!Number.isFinite(number)) {
    fail("numeric")
    return
  }

  if (rules.only_integer && !Number.isInteger(number)) fail("only_integer")
  if (isNumber(rules.greater_than) && !(number > rules.greater_than)) fail("greater_than")
  if (isNumber(rules.greater_than_or_equal_to) && !(number >= rules.greater_than_or_equal_to)) fail("greater_than_or_equal_to")
  if (isNumber(rules.less_than) && !(number < rules.less_than)) fail("less_than")
  if (isNumber(rules.less_than_or_equal_to) && !(number <= rules.less_than_or_equal_to)) fail("less_than_or_equal_to")
  if (rules.parity && Number.isInteger(number) && parityOf(number) !== rules.parity) fail("parity")
}

// Only canonical control output is judged; anything else is left to the server, whose
// parsers accept more shapes than the browser controls ever produce.
function typeFailure(type, text) {
  switch (type) {
    case "email": return !WHATWG_EMAIL.test(text)
    case "date": return ISO_DATE.test(text) && !isRealDate(text)
    case "datetime": return ISO_DATETIME.test(text) && !isRealDateTime(text)
    case "time": return ISO_TIME.test(text) && !isRealTime(text)
    case "json": return !isParseableJson(text)
    default: return false
  }
}

function matchesPattern(pattern, text) {
  try {
    return new RegExp(pattern).test(text)
  } catch {
    return null
  }
}

function includesValue(allowed, value) {
  const candidates = Array.isArray(value) ? value : [ value ]
  const permitted = allowed.map(String)

  return candidates.every((candidate) => permitted.includes(String(candidate)))
}

function isNumber(value) {
  return typeof value === "number" && Number.isFinite(value)
}

function parityOf(number) {
  return Math.abs(number % 2) === 1 ? "odd" : "even"
}

function isRealTime(text) {
  const [ hours, minutes, seconds = "0" ] = text.split(":")

  return Number(hours) < 24 && Number(minutes) < 60 && Number(seconds) < 60
}

// Date.parse rolls overflowing components forward, so the parts are compared directly.
function isRealDate(text) {
  const [ year, month, day ] = text.split("-").map(Number)
  const date = new Date(Date.UTC(year, month - 1, day))

  return date.getUTCFullYear() === year && date.getUTCMonth() === month - 1 && date.getUTCDate() === day
}

function isRealDateTime(text) {
  const [ date, time ] = text.split("T")

  return isRealDate(date) && isRealTime(time)
}

function isParseableJson(text) {
  try {
    JSON.parse(text)
    return true
  } catch {
    return false
  }
}
