# Replacement Implementation Prompt Pack

This is the execution prompt pack for delivering KrudminAI as a modern functional replacement for Krudmin Classic. It supersedes the task ordering in [implementation_prompts.md](implementation_prompts.md) where the two conflict. The older document remains useful as historical beta-foundation evidence; this document owns the missing field, relationship, lookup, and parity work.

## Use

Run the program in numerical order without waiting for a user to select or approve each prompt. Do not skip a dependency or relabel a partial feature as independently proven because the companion demo passes. Every task must update focused tests, the affected docs, and [capability_registry.json](capability_registry.json). QR-code fields are explicitly out of scope for this replacement program.

## Delivery And Evidence Phases

P1 through P12 are autonomous delivery prompts. Complete each prompt's runtime contract, focused engine tests, documentation, and any prompt-local generated-host request proof, then immediately begin the next eligible prompt. Do not block an earlier prompt on cross-cutting browser evidence, release-lane history, or a full independent host scenario that requires capabilities from later prompts; record those obligations as deferred P13 release evidence instead.

P13 is the evidence-consolidation prompt. It must prove the completed supported capability set in an independent generated host, including browser/accessibility behavior and release evidence. Deferred evidence does not authorize a beta or replacement-parity claim before P13 passes, but it also does not stop sequential implementation work.

## Single-Prompt Autonomous Execution

Use the prompt below to start the whole program without manually issuing `P1`, `P2`, and later prompts. The agent must continue through eligible tasks in order and use [classic_parity_ledger.json](classic_parity_ledger.json) as its durable resume point after a VS Code timeout, context limit, or deliberate pause. An interrupted run is not a completed task.

```text
Implement the complete program in docs/replacement_implementation_prompt_pack.md autonomously, starting with P0 and continuing through each next eligible prompt in numerical order.

Do not wait for me to select the next prompt. After a prompt meets its delivery acceptance criterion, update the parity ledger, capability registry, tests, and documentation, then immediately begin the next eligible prompt. Record deferred P13 evidence instead of stopping. Do not skip P1 through P6: field adapters, scalar/date/number formatting, local association lookup, remote large-dataset lookup, and relationship completion are mandatory replacement work.

Maintain a durable progress record in the parity ledger. For every prompt, record: current state, implementation files, tests run and exact results, independent generated-host evidence, browser/accessibility evidence, unresolved risks, and the next concrete unfinished step. On a timeout, context limit, or restart, read that record and resume the first unfinished acceptance criterion without asking me to restate prior requirements.

Work in small validated vertical slices inside each prompt. A delivery prompt can be complete when its runtime and prompt-local proof pass, while its registry status remains `implemented` rather than `independently_proven` until P13 completes deferred evidence. Never claim a beta gate or replacement parity based only on code existence, engine tests, or companion-demo evidence.

If a real product decision is required, investigate the local Krudmin reference and current docs, choose the safest reversible default when the manifesto permits it, record the decision and rationale, and continue. Stop only when a decision cannot be safely made from the manifesto or would change a documented security invariant; report the exact decision, options, consequences, and blocked acceptance criterion.

Preserve authentication by default; tenant scope then policy scope then filters, sort, and pagination; deny-by-default authorization; transactional audit behavior; and read-only AI unless an explicit approval policy authorizes a traced mutation. Use Classic only as a behavioral reference. Do not introduce jQuery, Select2, global JavaScript coupling, or implicit authorization.

At every task boundary, run the focused validation required by that task plus `git diff --check` and capability-registry parsing. Keep moving automatically after passing validation. At every interruption point, leave the repository and the progress record in a truthful resumable state.
```

Append this block to every prompt:

```text
Execution requirements:
- Read AGENTS.md, docs/product_scope.md, docs/architecture.md, docs/capability_registry.json, and the docs for the affected feature before editing.
- Treat /Users/mamerced/projects/krudmin as a behavioral reference only. Do not copy jQuery, Select2, global JavaScript patterns, or Classic's implicit authorization.
- Preserve authentication by default; tenant scope then policy scope then filters, sort, and pagination; deny-by-default authorization; and read-only AI absent explicit traced approval.
- Implement one small vertical slice. Before the first edit, state a falsifiable local hypothesis and the focused check that could disprove it. Run that check immediately after the edit.
- Mark delivery capabilities `implemented` after their runtime contract, focused tests, documentation, and prompt-local proof pass. Reserve `independently_proven` for P13 after its independent-host and required browser/accessibility evidence passes.
- Do not change the beta outcome from hold or make replacement-parity claims without the documented evidence.
- Report changed files, commands and results, remaining gaps, and the next numbered prompt.
```

## P0: Reconcile the Parity Ledger

```text
Implement P0 from docs/replacement_implementation_prompt_pack.md.

Create the authoritative, machine-readable Krudmin Classic parity ledger. Inventory every supported Classic capability: resource metadata, supported field types, associations, search, sorting, pagination, CRUD responses, actions, workflows, bulk actions, inline editing, dashboards, audit UI, navigation, themes, generators, and migration behavior. QR-code fields are a documented exclusion. Compare each against KrudminAI as implemented, partial, missing, or independently proven.

Add a verifier that rejects inconsistent ledger and capability-registry claims. Update docs so no document says field adapters, typed generic rendering, or replacement parity already exist. Do not implement runtime features in this task.

Acceptance: every feature has an owner prompt, dependencies, and evidence requirement; the verifier passes; beta remains hold.
```

## P1: Field Adapter Core and Schema Inference

```text
Implement P1 from docs/replacement_implementation_prompt_pack.md.

Build the first-class KrudminAI field adapter registry and resource field DSL. An adapter must own form, list, show, JSON, export, AI-context, filtering, parameter, blank-value, and field-policy behavior. Add safe Active Record schema inference plus explicit field overrides. Route generic resource rendering through adapters while preserving existing list/form/show metadata and host template overrides.

Do not implement every concrete field type in this slice. Start with the registry, a base adapter, a string adapter, and tests proving denied fields never invoke or serialize adapter values.

Acceptance: generic rendering no longer hard-codes a text field; a host can declare `field :title, :string`; inferred and explicit adapter selection are tested in engine and independent generated host.
```

## P2: Core Scalar Adapters and Formatting

```text
Implement P2 from docs/replacement_implementation_prompt_pack.md.

Extend the field adapter system with string, text, email, password, hidden, number, decimal, currency, percentage, boolean, date, time, datetime, JSON, enum, and identifier adapters. Use native accessible controls first. Define locale/time-zone parsing and display semantics, precision and currency formatting, enum option contracts, JSON validation/presentation, and password non-disclosure.

Acceptance: a generated host proves every adapter in form, list, show, JSON, CSV export, and AI context. Each applicable adapter exposes a typed filter definition for P7; P7 owns filter controls and query behavior. Tests cover invalid values, time zones, formatting, hidden/password redaction, and denied read/write fields. Independent browser/accessibility evidence for the complete adapter surface is consolidated in P13 after P8 presentation and P7 discovery behavior exist.
```

## P3: Sensitive, Rich, and Media Field Adapters

```text
Implement P3 from docs/replacement_implementation_prompt_pack.md.

Add masked/reveal-controlled, rich-text, file, image, and computed-display adapters. Use explicit Action Text and Active Storage host contracts; do not assume a host has either dependency. Separate reveal authorization from ordinary read authorization and audit every reveal. Ensure sensitive values cannot leak through JSON, CSV, audit diffs, logs, or AI context.

Acceptance: a Member-style generated resource safely renders a profile image, attachment, rich notes, computed label, and masked identifier; unauthorized reveal and all indirect disclosure paths are tested.
```

## P4: Local Belongs-To Lookup

```text
Implement P4 from docs/replacement_implementation_prompt_pack.md.

Add a `belongs_to` field adapter for small authorized collections. It must provide tenant/policy-scoped local options, configurable label/display fields, selected-value rendering, optional authorized association links, and forged foreign-key rejection through canonical protected relations. Integrate it with list/show/filter behavior.

Acceptance: an independent generated host proves rank, province, and recruiter lookups; cross-tenant, policy-denied, unreadable-label, and forged-ID submissions fail without persistence or audit leakage.
```

## P5: Remote Belongs-To Combobox for Large Datasets

```text
Implement P5 from docs/replacement_implementation_prompt_pack.md.

Build the non-jQuery replacement for Classic remote Select2 lookups using a Turbo/Stimulus accessible combobox. Provide authenticated lookup endpoints, debouncing, minimum query length, bounded/paginated results, cancellation, loading/no-result/error states, selected-label restoration, keyboard navigation, and safe result announcements. Scope every result and submitted ID by tenant, policy, authorization provider, and field-read policy.

Acceptance: browser tests prove keyboard selection, loading, no-result, errors, limits, tenant isolation, label redaction, and forged-ID rejection against a large generated fixture. No jQuery or Select2 dependency may be introduced.
```

## P6: Complete Relationship Adapters and Nested Editing

```text
Implement P6 from docs/replacement_implementation_prompt_pack.md.

Complete relationship support with has_many, has_one, nested belongs_to where safe, and authorized has_many_ids multi-select. Make ordering, relationship display fields, empty state, related links, validation retention, add/remove behavior, parent ownership checks, tenant checks, field policy, and transaction/audit behavior explicit. Record a product decision for polymorphic and arbitrary-depth nesting rather than silently omitting them.

Acceptance: independent generated hosts prove Member/Rank/Province, Car/Passenger, Car/Insurance, and social-account workflows including validation failure, remove, cross-tenant ID attacks, and policy-denied child fields.
```

## P7: Field-Driven Search, Filters, Sorting, and Views

```text
Implement P7 from docs/replacement_implementation_prompt_pack.md.

Move filters and search to the field adapter contract. Deliver text operators, enum/boolean filters, numeric and date/datetime ranges, association filters using local/remote lookup, stable sortable headers, pagination, reset behavior, and a documented privacy-safe saved-search/view policy if persistence is added. Preserve canonical query order exactly.

Acceptance: Member-style browser and request tests prove empty and populated search without server errors, invalid payload rejection, reset, association filtering, date formatting/ranges, pagination, sorting, and tenant isolation.
```

## P8: Form, List, and Detail Presentation for Dense Admin Workflows

```text
Implement P8 from docs/replacement_implementation_prompt_pack.md.

Add resource form sections and layout metadata as the modern successor to PRESENTATION_METADATA. Build adapter-driven high-density lists and record detail layouts with responsive priorities, association links, status text, image thumbnails, formatted dates/currency/identifiers, relationship blocks, and accessible labelled actions. Keep host overrides explicit and avoid arbitrary CSS-class passthrough.

Acceptance: a Member resource remains usable and scannable at 1440px, 768px, and 390px; form validation/focus works across sections; browser screenshots and accessibility assertions pass.
```

## P9: Actions, Workflows, Inline Edit, and Bulk Operations

```text
Implement P9 from docs/replacement_implementation_prompt_pack.md.

Complete declared actions with labels, Lucide icons, placement, confirmation, HTTP method, and semantic variants. Add explicit activate/deactivate behavior, a host-selectable state-machine adapter/presenter, adapter-safe inline editing, and scoped bulk operations. Every target must resolve through the canonical protected relation, receive per-record authorization, and emit correct audit behavior.

Acceptance: tests cover prohibited UI/endpoints, GET safety, invalid transition, mixed-authorization selections, cross-tenant targets, confirmation, audit failure, and HTML/JSON/Turbo outcomes.
```

## P10: Dashboards and Audit as Product Surfaces

```text
Implement P10 from docs/replacement_implementation_prompt_pack.md.

Add list and chart dashboard widgets with accessible summaries and safe drill-down. Build durable audit retention, authorized activity history, change diffs, sensitive redaction, tenant/policy-scoped audit search, and a reference Active Record audit-store contract. Retain transactional mutation/audit guarantees.

Acceptance: a generated host proves dashboard visibility, chart/list drill-down, activity history, diff rendering, audit search, and no leakage of unreadable, sensitive, or cross-tenant values.
```

## P11: Generators and Migration for the Completed Runtime

```text
Implement P11 from docs/replacement_implementation_prompt_pack.md.

Upgrade generators for typed resources, field adapters, associations, themes, audit setup, and workflow integration. Expand legacy migration audit to map ATTRIBUTE_TYPES and Classic association/action metadata as automatic, assisted, manual, or blocked. Add codemods only for deterministic safe transformations.

Acceptance: a clean host generator creates a typed Member-style resource with tests; reruns are idempotent; a representative Classic Car/Passenger/Insurance manager receives a precise migration report and independently migrated-host evidence.
```

## P12: Durable Import, Export, and AI Operations

```text
Implement P12 from docs/replacement_implementation_prompt_pack.md.

Complete import/export through authenticated UI/controllers, field-adapter serialization, durable atomic idempotency records, jobs, progress, retry, cancellation, formula/encoding limits, masks, and audit. Then connect AI to field adapters with durable redacted traces, reviewable proposals, async lifecycle, provider failure handling, and explicit approval-gated mutations.

Acceptance: browser/request tests prove job recovery, duplicate prevention, sensitive export prevention, trace redaction, tenant/field isolation, and no AI mutation without approval, normal validation, audit, and a pre-mutation trace.
```

## P13: Independent AOD-Style Host and Release Evidence

```text
Implement P13 from docs/replacement_implementation_prompt_pack.md.

Create an independently generated Rails host that proves the complete supported replacement capability with sanitized fixtures: members, ranks, provinces, users, teams, photos/files, masked IDs, local and remote relationships, social accounts, statuses, workflows, advanced search, dashboards, audit history, import/export, and approved AI flows. Add Spanish locale coverage and browser/accessibility proof at desktop, tablet, and mobile widths. Resolve root lint and establish remote CI history for supported Rails/Ruby lanes.

Acceptance: each parity-ledger item has engine plus independent-host evidence; the registry only promotes proven features; beta/1.0 decisions remain evidence-based and are changed only through explicit approval.
```

## Prompt Selection

- `implement P0` starts ledger reconciliation.
- `implement next replacement prompt` runs the first incomplete prompt in order.
- `implement P5` runs the remote association lookup task directly, but only after P1 through P4 meet their acceptance criteria.
- `audit replacement status` performs a read-only ledger and evidence review; it must not claim completion from companion evidence alone.