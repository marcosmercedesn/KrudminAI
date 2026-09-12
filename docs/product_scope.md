# KrudminAI Project Manifesto

## Purpose

KrudminAI is a modern, secure Rails engine for building real back-office applications: admin panels, CRMs, ERPs, membership systems, and operational tools. It is intended to replace the useful functional scope of Krudmin Classic without copying its jQuery-era architecture or its unsafe implicit behavior.

The target is not a thin CRUD demo. A host must be able to build dense, relationship-heavy operational resources with dates, formatted numbers, status workflows, sensitive data, attachments, search, large-dataset lookup, audit history, and responsive accessible UI.

## Product Commitments

KrudminAI must provide a resource-owned, extensible field and relationship system. The engine owns consistent behavior for form, list, detail, search, JSON, export, dashboard, and AI contexts; a host may extend adapters but must not need custom templates for ordinary data types.

The required baseline includes:

- Scalar fields: string, text, email, password, hidden, number, decimal, currency, percentage, boolean, date, time, datetime, JSON, enum, and formatted identifiers.
- Sensitive and visual fields: masked/reveal-controlled values, rich text, files, images, QR codes, and safe computed displays where a host enables the required Rails integration.
- Relationships: local and remote `belongs_to` lookup, direct `has_many`, `has_one`, authorized multi-select relationships, and explicit decisions for any polymorphic or deeper nesting support.
- Operations: CRUD, archive/restore where configured, declared actions, workflow transitions, inline editing where adapter-safe, and tenant/policy-safe bulk operations.
- Discovery: typed filters, sorting, pagination, association search, and safe state persistence or saved views when enabled.
- Operational context: dashboards, audit history and change diffs, navigation, themes, imports/exports, and AI assistance that respects field and relationship policy boundaries.

Classic behavior is the functional baseline, not the implementation blueprint. KrudminAI must meet or exceed useful workflows with Rails 8, Ruby 4-compatible support policy, Propshaft-native assets, Turbo, Stimulus, semantic HTML, and accessible browser behavior. It must not introduce jQuery, Select2, global JavaScript coupling, or unaudited implicit data access to achieve parity.

## Security Invariants

- Admin workflows require authentication by default.
- Every data query applies tenant scope, policy scope, filters, sort, then pagination. Exports, dashboards, lookups, relationship choices, and AI contexts use the same protected path.
- Authorization denies by default. UI affordances, lookup results, serialized values, and mutation endpoints use the same decision.
- Field read, write, and reveal permissions are independent where needed. Sensitive values do not leak through logs, audit diffs, exports, JSON, browser presentation, or AI context.
- Every mutation, including nested, bulk, import, action, workflow, and approved AI mutation, resolves targets through canonical protected relations and records a traceable audit event.
- AI is read-only by default. A mutation requires an explicit approval policy, a durable reviewed proposal where applicable, normal mutation validation, and a pre-mutation trace.

## Evidence Standard

Code, a unit test, or the companion demo does not establish replacement parity. A capability is complete only when its documented contract, focused engine tests, generated-host request tests, and required browser/accessibility evidence exist.

The capability registry must classify each feature as `implemented`, `partial`, `missing`, or `independently_proven`. Release decisions must use that evidence, not implementation intent. The current beta outcome remains `hold` until its recorded blockers close.

## Delivery Order

The field adapter core, scalar formatting, local and remote relationship lookup, and complete association support are first-order delivery work. They cannot be deferred behind visual polish, AI expansion, or release messaging. The executable task order is in [replacement_implementation_prompt_pack.md](replacement_implementation_prompt_pack.md).

## Non-goals

KrudminAI is not a public-site CMS, an authentication provider, an authorization framework, or an autonomous mutation agent. Provider implementations remain host-application decisions behind explicit engine contracts. A capability may be excluded only through a documented product decision that names the replacement behavior, owner, migration impact, and evidence required for release.