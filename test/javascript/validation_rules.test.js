import test from "node:test"
import assert from "node:assert/strict"
import { parseRules, isBlank, validateValue } from "../../app/javascript/krudmin_ai/validation/rules.js"

const keys = (failures) => failures.map((failure) => failure.key)

test("parses a rule payload and falls back to an empty rule set", () => {
  assert.deepEqual(parseRules('{"required":true}'), { required: true })
  assert.deepEqual(parseRules("not json"), {})
  assert.deepEqual(parseRules(""), {})
  assert.deepEqual(parseRules(null), {})
  assert.deepEqual(parseRules("[1,2]"), [ 1, 2 ])
})

test("treats nullish, empty, whitespace, and empty selections as blank", () => {
  assert.equal(isBlank(null), true)
  assert.equal(isBlank(undefined), true)
  assert.equal(isBlank("   "), true)
  assert.equal(isBlank([]), true)
  assert.equal(isBlank("0"), false)
  assert.equal(isBlank([ "1" ]), false)
})

test("reports a blank required value and nothing else", () => {
  const rules = { required: true, minimum: 5, pattern: "^abc$", numeric: true, type: "email" }

  assert.deepEqual(keys(validateValue(rules, "")), [ "required" ])
})

test("skips every non-required rule on a blank value so the client never over-rejects", () => {
  const rules = { minimum: 5, maximum: 2, pattern: "^abc$", one_of: [ "a" ], numeric: true, type: "json" }

  assert.deepEqual(validateValue(rules, ""), [])
})

test("evaluates length rules against the string value", () => {
  assert.deepEqual(keys(validateValue({ minimum: 3 }, "ab")), [ "minimum" ])
  assert.deepEqual(validateValue({ minimum: 3 }, "abc"), [])
  assert.deepEqual(keys(validateValue({ maximum: 3 }, "abcd")), [ "maximum" ])
  assert.deepEqual(keys(validateValue({ is: 4 }, "abc")), [ "is" ])
  assert.deepEqual(validateValue({ is: 4 }, "abcd"), [])
})

test("evaluates patterns and ignores a pattern the browser cannot compile", () => {
  assert.deepEqual(validateValue({ pattern: "^[a-z]+$" }, "abc"), [])
  assert.deepEqual(keys(validateValue({ pattern: "^[a-z]+$" }, "abc1")), [ "pattern" ])
  assert.deepEqual(validateValue({ pattern: "(" }, "anything"), [])
})

test("evaluates inclusion and exclusion sets across scalar and multiple values", () => {
  assert.deepEqual(validateValue({ one_of: [ "draft", "published" ] }, "draft"), [])
  assert.deepEqual(keys(validateValue({ one_of: [ "draft" ] }, "archived")), [ "one_of" ])
  assert.deepEqual(validateValue({ one_of: [ "1", "2" ] }, [ "1", "2" ]), [])
  assert.deepEqual(keys(validateValue({ one_of: [ "1" ] }, [ "1", "3" ])), [ "one_of" ])
  assert.deepEqual(keys(validateValue({ none_of: [ "admin" ] }, "admin")), [ "none_of" ])
  assert.deepEqual(validateValue({ none_of: [ "admin" ] }, "editor"), [])
})

test("compares numeric bounds with the server's inclusive and exclusive semantics", () => {
  assert.deepEqual(keys(validateValue({ numeric: true }, "abc")), [ "numeric" ])
  assert.deepEqual(keys(validateValue({ numeric: true, only_integer: true }, "1.5")), [ "only_integer" ])
  assert.deepEqual(keys(validateValue({ numeric: true, greater_than: 0 }, "0")), [ "greater_than" ])
  assert.deepEqual(validateValue({ numeric: true, greater_than: 0 }, "1"), [])
  assert.deepEqual(validateValue({ numeric: true, greater_than_or_equal_to: 0 }, "0"), [])
  assert.deepEqual(keys(validateValue({ numeric: true, less_than: 10 }, "10")), [ "less_than" ])
  assert.deepEqual(validateValue({ numeric: true, less_than_or_equal_to: 10 }, "10"), [])
})

test("checks parity only for integers", () => {
  assert.deepEqual(keys(validateValue({ numeric: true, parity: "odd" }, "2")), [ "parity" ])
  assert.deepEqual(validateValue({ numeric: true, parity: "odd" }, "3"), [])
  assert.deepEqual(validateValue({ numeric: true, parity: "even" }, "-4"), [])
  assert.deepEqual(keys(validateValue({ numeric: true, parity: "even" }, "-3")), [ "parity" ])
  assert.deepEqual(validateValue({ numeric: true, parity: "odd" }, "2.5"), [])
})

test("compares a confirmation against its companion value", () => {
  assert.deepEqual(validateValue({ confirms: "email_confirmation" }, "a@b.com", { confirmation: "a@b.com" }), [])
  assert.deepEqual(keys(validateValue({ confirms: "email_confirmation" }, "a@b.com", { confirmation: "c@d.com" })), [ "confirms" ])
  assert.deepEqual(keys(validateValue({ confirms: "email_confirmation" }, "a@b.com")), [ "confirms" ])
})

test("judges adapter types the way the server parses them", () => {
  assert.deepEqual(validateValue({ type: "email" }, "person@example.com"), [])
  assert.deepEqual(keys(validateValue({ type: "email" }, "person@@example")), [ "type" ])
  assert.deepEqual(validateValue({ type: "date" }, "2026-02-28"), [])
  assert.deepEqual(keys(validateValue({ type: "date" }, "2026-02-31")), [ "type" ])
  assert.deepEqual(validateValue({ type: "datetime" }, "2026-02-28T10:30"), [])
  assert.deepEqual(keys(validateValue({ type: "datetime" }, "2026-02-31T10:30")), [ "type" ])
  assert.deepEqual(validateValue({ type: "time" }, "23:59:59"), [])
  assert.deepEqual(keys(validateValue({ type: "time" }, "24:00")), [ "type" ])
  assert.deepEqual(validateValue({ type: "json" }, '{"a":1}'), [])
  assert.deepEqual(keys(validateValue({ type: "json" }, "{a:1}")), [ "type" ])
})

test("leaves non-canonical date and time input to the server", () => {
  assert.deepEqual(validateValue({ type: "date" }, "20260228"), [])
  assert.deepEqual(validateValue({ type: "time" }, "half past ten"), [])
})

test("returns the server-generated message and a null placeholder when none was projected", () => {
  const withMessage = validateValue({ required: true, messages: { required: "Title can't be blank" } }, "")
  assert.deepEqual(withMessage, [ { key: "required", message: "Title can't be blank" } ])

  const withoutMessage = validateValue({ required: true }, "")
  assert.deepEqual(withoutMessage, [ { key: "required", message: null } ])
})

test("reports every failing rule so the field can list them all", () => {
  const failures = validateValue({ minimum: 5, pattern: "^[a-z]+$" }, "A1")

  assert.deepEqual(keys(failures).sort(), [ "minimum", "pattern" ])
})
