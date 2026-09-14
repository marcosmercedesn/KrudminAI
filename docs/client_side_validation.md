# Client-Side Validation

KrudminAI projects server-side validation into the browser so a form can report problems before it is submitted, and so a blocked submission moves the user to the first field that needs attention.

The server remains authoritative. Client rules are an acceleration layer: they are always narrower than, or equal to, their server counterpart, and with JavaScript unavailable the form behaves exactly as it did before this capability existed.

## How A Rule Reaches The Browser

`KrudminAI::Validations::Introspector` merges three sources into one normalized rule descriptor, in this order, keeping the most restrictive value on conflict:

1. **Column metadata** — `null: false` implies `required`, a string or text `limit` becomes `maximum`, and a decimal `scale` becomes `step`. Nullability is ignored when the column has a default or is boolean, because the server accepts a blank submission in those cases.
2. **Model validators** — `validators_on(attribute)`, matched on `validator.kind` rather than class identity so the projection works without ActiveModel loaded and so unknown validators fail closed.
3. **Adapter constraints** — `Adapter#validation_constraints`, which reports what each adapter already enforces in `parameter` and `validate_submission`.

Reach it through `Resources::Base.validation_rules(attribute, record, context)` or, for nested rows, `Relationship#validation_rules(attribute, record, context, resource)`.

### Projected Validators

| Validator | Projected rule |
| --- | --- |
| `presence` | `required` |
| `length` | `minimum`, `maximum`, `is` |
| `numericality` | `numeric`, `only_integer`, `greater_than`, `greater_than_or_equal_to`, `less_than`, `less_than_or_equal_to`, `parity` |
| `format` (`:with`) | `pattern` |
| `inclusion` / `exclusion` | `one_of` / `none_of` |
| `acceptance` | `required`, on boolean adapters only |
| `confirmation` | `confirms` |

### Adapter Constraints

| Adapter | Contributed rules |
| --- | --- |
| `Number`, `Identifier` | `numeric`, `only_integer`, `step` |
| `Decimal`, `Currency`, `Percentage` | `numeric`, `step` |
| `Email` | `type: :email` |
| `Date`, `Time`, `DateTime`, `Json` | `type` |
| `Enum` | `one_of`, plus `required` when blanks are disallowed |
| `BelongsTo` | `required` when the blank option is withheld |
| `HasManyIds` | `multiple` |

`Email` is the one rule whose counterpart is the rendered control rather than a model validator: the adapter renders `<input type="email">`, which browsers already validate natively. The projected rule uses the WHATWG email pattern so it never rejects input the native control accepts.

`BelongsTo` deliberately does not project its allowed identifiers. The rendered select is already limited to the authorized collection, and publishing the identifier list would leak the authorized scope.

## What Is Never Projected

These stay server-only, and a dropped rule is not a defect — the server catches that case on submit exactly as it did before:

- `uniqueness`, which is database dependent and would become a record-enumeration oracle.
- Custom validator classes and `validate :method`, which never appear in a projectable form.
- Any validator carrying `:if`, `:unless`, or `:on`, because the condition cannot be resolved statically.
- Any field whose read or write decision is denied for the current `AccessContext`.
- Any field rendered by the `Password`, `Hidden`, or `Computed` adapters, which report `validation_projectable? == false`.
- Regular expressions that do not translate faithfully. Only fully string-anchored `\A…\z` patterns are converted to `^…$`. A Ruby `^…$` pattern is line-anchored while its JavaScript equivalent is string-anchored, so translating it would reject multi-line input the server accepts. Named groups, POSIX classes, `\p`, `\h`, and the `m` and `x` flags are dropped as well.

## Messages

Messages are generated on the server through `errors.full_message(attribute, errors.generate_message(attribute, key, options))`, so client text matches `full_messages_for` exactly and honors host locale overrides. Adapter type messages come from the engine catalog under `krudmin_ai.validation.*`.

No validation message is ever written in JavaScript. When a message cannot be generated, the key is omitted and the browser's own `validationMessage` is used instead.

## Markup Contract

`Adapter#control_options` emits native constraint attributes for writable fields only. They are adapter-aware, because the attributes are not interchangeable between control families:

| Control family | Native attributes |
| --- | --- |
| `String`, `Email` | `required`, `aria-required`, `minlength`, `maxlength`, `pattern` |
| `Text`, `Json`, `RichText` | the same, minus `pattern`, which is invalid on `<textarea>` |
| `Number`, `Decimal` | `required`, `min`, `max`, `step` |
| `Boolean`, `Date`, `Time`, `DateTime`, `Enum`, `BelongsTo`, `File` | `required` |

`min` and `max` are only derived from inclusive bounds. HTML has no exclusive comparison, so an exclusive `greater_than` is left to the rule engine rather than approximated into a stricter control.

Every field rendered by `ui/field` carries:

- `data-krudmin-ai-validation-field`, naming the attribute.
- `data-krudmin-ai-validation-rules`, the JSON rule descriptor, present only when rules were projected.
- A stable error node, `<p id="<field>-error" class="krudmin-ai-field-error" role="alert" hidden>`, always present so server-rendered and client-generated messages share one presentation.
- An `aria-describedby` that merges the authorization access-note id and the error id.

Element ids come from `form.field_id`, so nested rows produce unique ids per row.

The validation summary is always rendered, `hidden` when the form is clean, and exposes `summary` and `summaryList` targets. Each item anchors to its control when the attribute is a readable form field, and falls back to plain text for `:base` errors.

## Browser Behavior

`krudmin-ai-form-validation` is declared on the form. It sets `form.noValidate = true` on connect and restores it on disconnect, so a controller that never boots leaves native browser validation in place.

Events are delegated from the form rather than bound per control, which means rows added by the nested editor need no rebinding.

| Event | Behavior |
| --- | --- |
| `focusout`, `change` | Validate the field and mark it touched. |
| `input` | Re-validate only a field that is already touched and already showing a message. |
| `submit` | Validate every field; if any fail, stop the submission, populate the summary, and reveal the first invalid field. |

Revealing a field unhides `[hidden]` ancestors, opens enclosing `<details>`, scrolls the field into view honoring `prefers-reduced-motion`, and focuses its control with `preventScroll`. Focus is never taken on page load, only after a submission attempt.

Fields are skipped when their control is disabled or when any ancestor is hidden, which covers write-denied fields and nested rows marked for removal.

Rule evaluation lives in `krudmin_ai/validation/rules.js`, a pure module with no DOM access. Its governing rule: **on a blank value only `required` is evaluated and every other rule is skipped**, which is narrower than Rails and removes any need to track `allow_blank`.

Server errors are replaced rather than preserved when a submission is attempted. Preserving them would let an error the client cannot reproduce, such as uniqueness, block resubmission permanently.

All message text is written with `textContent`. Validation messages interpolate user-supplied values, so this is an XSS boundary.

### Remote Lookup, Nested Rows, And Inline Editing

A `RemoteBelongsTo` field keeps its value in a hidden input while the user types in a separate combobox, so the controller distinguishes the value control (`data-krudmin-ai-validation-control`) from the focus target (`data-krudmin-ai-validation-focus`). Choosing a result dispatches a bubbling `change` on the hidden input, because assigning `value` in script fires no event.

Nested rows project the child model's validators through the relationship's own field authorizers, which are a separate decision from the parent's. A nested field with no declared type falls back to a text adapter so it still receives native constraints.

Inline editing renders the same field markup with a visually hidden label and carries its own validation controller per row form.

## Evidence

| Layer | Location |
| --- | --- |
| Rule projection | `spec/lib/krudmin_ai/validations/introspector_spec.rb` |
| Rule evaluation | `test/javascript/validation_rules.test.js` |
| Rendered markup | `demo/test/integration/validation_markup_test.rb` |
| Browser behavior | `demo/test/system/client_side_validation_test.rb` |

```sh
bundle exec rspec spec/lib/krudmin_ai/validations/introspector_spec.rb
npm run test:javascript
cd demo && bin/rails test test/integration/validation_markup_test.rb
cd demo && bin/rails test test/system/client_side_validation_test.rb
```

The browser suite proves that an invalid submission never reaches the server, that focus and scrolling land on the first field needing attention, that the summary is anchored, that a dynamically added nested row is validated, that a row marked for removal is excluded, and that inline editing validates within its own row form.

Companion evidence does not replace the independent generated-host browser matrix required for beta claims.

## Deliberately Out Of Scope

Asynchronous uniqueness checking is not implemented. It would require an endpoint that applies tenant scope and policy scope, returns only a boolean, and is debounced and rate limited; without that discipline it becomes a record-enumeration oracle. Uniqueness remains a server decision.
