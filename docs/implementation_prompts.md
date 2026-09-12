# KrudminAI Implementation Prompts

This is the authoritative execution backlog for KrudminAI. It is derived from the replacement inventory, beta readiness checkpoint, capability registry, architecture, product scope, and current repository evidence.

The previous index omitted a legacy-core requirement: nested forms and association editors. This index gives every pending commitment an explicit task, names the evidence required to close it, and distinguishes implemented engine contracts from companion-demo and generated-host proof.

## Evidence States

- **Implemented contract**: engine code and focused tests exist.
- **Companion evidence**: the local demo proves behavior, but an independent generated host does not.
- **Pending**: complete implementation and executable evidence do not exist.
- **Deferred**: deliberate post-beta or post-1.0 work. Deferred work remains visible and assigned.

The query and mutation pipelines, dashboard widget primitives, UI foundations, generator contracts, and read-only AI primitives have implemented-contract evidence. The companion demonstrates portions of CRUD, dashboards, navigation, visual presentation, audit events, and AI. The beta checkpoint remains authoritative: generic host rendering, association editing, formal provider contracts, controller-level JSON/Turbo delivery, durable audit, generated-host execution, and repeatable browser confidence are incomplete.

## Rules For Every Task

- Read and honor [AGENTS.md](../AGENTS.md) before changing behavior.
- Read [architecture.md](architecture.md), [beta_readiness_checkpoint.md](beta_readiness_checkpoint.md), [rails8_replacement_inventory.md](rails8_replacement_inventory.md), and all capability documents touched by the slice.
- Preserve authentication by default; tenant scope, then policy scope, then filters, sort, and pagination; deny-by-default authorization; and read-only AI unless an explicit approval policy permits a traced mutation.
- Update focused tests, affected documentation, and [capability_registry.json](capability_registry.json) in the same change. Do not upgrade a registry status without the evidence the task requires.
- Preserve host override points. Do not import Krudmin's jQuery-era architecture; use Rails 8, Turbo, Stimulus, and module-based assets.
- Start each task with its narrow baseline. Run `git diff --check` after every task and parse the capability registry whenever it changes.

## Quick Task Map

### Beta foundation

- 0 - Evidence Baseline and Backlog Reconciliation
- 1 - Generic Resource Delivery and Generated-Host Conformance
- 2 - Nested Relationships and Association Editors
- 3 - Provider Contracts and Security Baseline
- 4 - Response Formats and Durable Audit
- 5 - Resource Query and Lifecycle Completion
- 6 - Field-Level Authorization and Denial Presentation
- 7 - Resource Actions and State Transitions
- 8 - Dashboard Lifecycle and Secure Drill-Downs
- 9 - Generator Execution, Host Contracts, and Documentation Sync
- 10 - Showcase Installation and Scenario Conformance
- 11 - UI Component Contract and Generated Resource States
- 12 - Navigation, Admin Shell, and Theme Conformance
- 13 - Browser, Accessibility, and Visual Regression Policy
- 14 - Compatibility Matrix and Release Automation
- 15 - Observability, Governance, and Operational Readiness
- 16 - Beta Evidence Reconciliation and Release Decision

### Product delivery after beta

- 17 - Import, Export, and Large Data Operations
- 18 - Production AI Providers, Routing, and Trace Operations
- 19 - AI V1.1: Extraction, Cross-Record Analysis, Narratives, and Templates
- 20 - AI V2: Guided Workflows, Approved Automation, and Multi-Source Analysis
- 21 - Migration Tooling and 1.0 Release Guarantees

## Aliases And Ordering

- `baseline` / `do 0` - Task 0
- `start` / `do 1` - Task 1
- `nested forms` / `associations` / `do 2` - Task 2
- `security` / `providers` / `do 3` - Task 3
- `formats` / `audit` / `do 4` - Task 4
- `query lifecycle` / `do 5` - Task 5
- `field authorization` / `do 6` - Task 6
- `actions` / `transitions` / `do 7` - Task 7
- `dashboards` / `do 8` - Task 8
- `generators` / `do 9` - Task 9
- `showcase` / `do 10` - Task 10
- `resource ui` / `do 11` - Task 11
- `navigation` / `admin shell` / `do 12` - Task 12
- `visual checks` / `do 13` - Task 13
- `compatibility` / `ci` / `do 14` - Task 14
- `operations` / `governance` / `do 15` - Task 15
- `beta decision` / `do 16` - Task 16
- `next` / `continue` - Run the first unfinished task in numerical order. Do not enter Tasks 17-21 until Task 16 records an explicit beta decision.

---

## Task 0: Evidence Baseline and Backlog Reconciliation

**State:** Pending. Run before each implementation slice.

**Goal:** Establish passing evidence, distinguish engine capability from companion-only evidence, and identify the affected files before behavior changes.

**Scope:** Run focused engine specs, relevant companion tests, and the generated-host proof where it exists. Reconcile the registry, checkpoint, and docs with executable evidence. Record discrepancies; do not relabel a capability merely because code exists.

**Acceptance criteria:** A report lists passing commands, failures, infrastructure limitations, and the next entry point; it labels each relevant capability as contract, companion, or generated-host evidence; and it identifies no unassigned requirement in the next task's source documents.

**Validation:** Narrow engine spec, relevant demo request/system test, JSON parsing, and `git diff --check`.

---

## Task 1: Generic Resource Delivery and Generated-Host Conformance

**State:** Pending beta blocker.

**Goal:** A host declares a resource and conventional Rails route, then receives secured default index, new, edit, show, create, update, and destroy delivery without resource-specific controller plumbing or templates.

**Scope:**
- Extend `Resources::Base` with labels and explicit list, form, and show field metadata.
- Add engine-owned generic rendering using `model`, `models`, `collection_path`, `resource_path`, `new_resource_path`, and `edit_resource_path`.
- Retain intentional host template and layout overrides.
- Remove demo ticket templates unless they demonstrate a documented override.
- Add a disposable generated Rails host with `OrdersResource`, thin controller, conventional routes, two tenants, and two roles.

**Non-goals:** Association editing, providers, response-format expansion, dashboards, AI, and broad field-type redesign. Task 2 owns association editing.

**Acceptance criteria:** A generated host boots with `resources :orders`; default engine index/new/edit/show render without host resource templates; forms derive permitted scalar inputs and generic helpers; layout and asset contracts render; generated-host requests prove anonymous denial, tenant-scoped lists, cross-tenant `404`, role-gated CRUD, and audit emission; and a stable system test proves list -> edit -> submit.

**Validation:** Generator contract, generated-host request/system tests, companion ticket suite, registry JSON parse, `git diff --check`.

---

## Task 2: Nested Relationships and Association Editors

**State:** Pending beta blocker and required legacy parity.

**Goal:** Let a secure parent form create, edit, validate, and remove authorized child records in one submission, beginning with `has_many` and covering `has_one` and nested `belongs_to` where the contract supports them.

**Scope:**
- Define relationship metadata, permitted nested attributes, labels, child fields, ordering, and maximum row limits.
- Support Rails `accepts_nested_attributes_for` without requiring host-specific form templates.
- Implement Turbo/Stimulus add/remove behavior with deterministic client identifiers, keyboard access, and no jQuery.
- Enforce parent and child tenant boundaries, action and field decisions, and policy checks before persistence. Reject crafted child identifiers outside the authorized association.
- Make parent and nested mutations atomic, return nested validation errors in the correct rows, and audit the parent operation with affected child references.
- Add generated-host `Car`/`Passenger` coverage for create, edit, validation failure, add, remove, and cross-tenant attacks.

**Non-goals:** Remote association search, polymorphic editing, arbitrary-depth nesting, bulk import, and a legacy-field API clone.

**Acceptance criteria:** Resource metadata describes a `has_many` editor without custom views; child rows can be added/removed accessibly; invalid nested data retains all rows with row-level errors; unauthorized or cross-tenant child IDs fail closed with no partial mutation; generated-host request/system tests cover two tenants and two roles; and docs name supported associations, Rails prerequisites, limits, and overrides.

**Validation:** Relationship pipeline specs, generated-host requests/system tests, companion regression suite, registry JSON parse, `git diff --check`.

---

## Task 3: Provider Contracts and Security Baseline

**State:** Pending beta blocker.

**Goal:** Formalize authentication, authorization, tenant resolution, audit, and notification providers with boot-time validation and fail-closed behavior.

**Scope:** Define executable provider interfaces, inputs/outputs, lifecycle hooks, errors, and test adapters; validate providers at boot; specify sessions, idle timeout and recovery readiness, CSRF, cookie attributes, headers, sensitive data in UI/logs/exports, tenant request resolution, and super-admin constraints; make missing, malformed, nil, false, and exception-producing provider results deny access or stop safely.

**Acceptance criteria:** Every provider has success and fail-closed conformance tests; misconfigured generated hosts fail predictably before serving protected resources; the demo remains bootable with explicit local adapters; and security documentation is actionable for generated hosts.

**Validation:** Provider/config specs, demo boot and requests, generated-host configuration-failure tests, registry JSON parse, `git diff --check`.

---

## Task 4: Response Formats and Durable Audit

**State:** Pending beta blocker.

**Goal:** Deliver normalized HTML, JSON, and Turbo Stream mutation responses through the controller and make audit recording durable, recoverable, and traceable.

**Scope:** Wire the response adapter through mutation success/error branches; define response envelopes and status mappings; use transaction-aware audit persistence or an outbox with retry/recovery semantics that cannot leave an unaccounted persisted mutation; document retention, redaction, access control, and recovery.

**Acceptance criteria:** Request tests exercise every mutation outcome in all three formats; authorization and validation errors cannot leak unscoped data; audit failure prevents the mutation or creates an exactly-defined durable recovery obligation; and recovery/idempotency tests prove no duplicated effective event.

**Validation:** Mutation/response/audit specs, generated-host requests, companion suite, registry JSON parse, `git diff --check`.

---

## Task 5: Resource Query and Lifecycle Completion

**State:** Pending Gate 1 completion.

**Goal:** Complete the data contract with eager loading, archival/soft deletion, N+1 safeguards, and public query parameter behavior.

**Scope:** Add explicit resource metadata for includes/preloads, archive visibility/mutation rules, and supported query parameters/errors. Preserve tenant -> policy -> filters -> sort -> pagination in every path. Add instrumentation or tests detecting avoidable association query regressions in list, show, and relationship views.

**Acceptance criteria:** Archived records have explicit default visibility and authorized restore/destroy semantics; render paths define and test eager loading; and invalid filters, sort, pagination, and archive parameters return documented safe results.

**Validation:** Query specs, generated-host archive requests, N+1-focused tests, docs/registry checks, `git diff --check`.

---

## Task 6: Field-Level Authorization and Denial Presentation

**State:** Pending Gate 1 completion.

**Goal:** Ensure field visibility and mutability use the same deny-by-default policy decisions as endpoints and cannot be bypassed by crafted parameters.

**Scope:** Add field read/write policy contracts and deterministic hidden/disabled/explained behavior. Apply them to presentation, permitted attributes, JSON, nested fields, AI context, dashboard outputs, and export selection. Define accessible HTML, Turbo, and JSON denials.

**Acceptance criteria:** Unauthorized fields are safely absent or represented and cannot persist through crafted requests; policy applies consistently to relationships, AI, dashboards, and exports; tenant/role tests cover read and write decisions.

**Validation:** Field-policy unit/request tests, generated-host role tests, accessibility checks, registry JSON parse, `git diff --check`.

---

## Task 7: Resource Actions and State Transitions

**State:** Pending required legacy parity.

**Goal:** Restore secure status transitions and declared custom actions as resource-owned, policy-aware workflows.

**Scope:** Define action/transition metadata, routes, labels, authorization predicates, audit events, Turbo/HTML/JSON results, and generator support. Keep state-machine implementation host-selectable. Reuse mutation, audit, and field-policy contracts.

**Acceptance criteria:** Unpermitted actions are unavailable in UI and denied at endpoints; successful actions are tenant-safe, audited, and consistently delivered; generated-host tests cover permitted, forbidden, invalid-state, and cross-tenant cases.

**Validation:** Action/transition specs, generator contract, generated-host requests, companion regression, registry JSON parse, `git diff --check`.

---

## Task 8: Dashboard Lifecycle and Secure Drill-Downs

**State:** Pending Gate 1 completion.

**Goal:** Turn widget primitives into a host-configurable dashboard lifecycle with secure visibility, rendering, refresh, and drill-down behavior.

**Scope:** Define widget registration, authorized visibility, empty/error/loading states, resource-aware drill-downs, and field-level output rules. Retain canonical scope/filter constraints for all aggregate, table, and drill-down data. Add generator support only after the runtime contract is stable.

**Acceptance criteria:** Inaccessible widgets and drill-downs are hidden or denied consistently; no widget leaks cross-tenant or field-denied information; generated-host tests cover visible/hidden widgets, filtered drill-downs, states, and table pagination.

**Validation:** Widget specs, generated-host/dashboard requests, companion dashboard suite, registry JSON parse, `git diff --check`.

---

## Task 9: Generator Execution, Host Contracts, and Documentation Sync

**State:** Pending Gate 1 completion.

**Goal:** Prove install, resource, action, dashboard, and docs-sync generator output boots and remains safe when re-run in real Rails hosts.

**Scope:** Execute generators in disposable hosts; cover namespaces, inflection, route insertion, collisions, idempotency, host-authored content preservation, and managed markers. Complete per-host capability registry bindings, enabled modules, provider bindings, flags, and release metadata without secrets. Add agent-safe resource/action/dashboard recipes and conformance expectations.

**Acceptance criteria:** Generated hosts boot, migrate, route, authorize, render, and execute generated tests; re-runs do not duplicate or overwrite host content; docs-only sync changes only documented artifacts; generated metadata accurately reports enabled host features.

**Validation:** Generator contracts plus disposable-host suite, docs-sync idempotency tests, registry JSON parse, `git diff --check`.

---

## Task 10: Showcase Installation and Scenario Conformance

**State:** Pending Gate 1/Gate 2 completion.

**Goal:** Make the showcase an installable, version-locked, executable proof of documented workflows rather than a companion-only demonstration.

**Scope:** Define lightweight demo/full showcase modes. Run seeded two-tenant, multi-role walkthroughs in CI for CRUD, associations, actions, dashboards, audit, navigation, filters, and AI boundaries. Tie scenarios to the capability registry and versioned docs.

**Acceptance criteria:** A clean host installs and boots the selected mode; scenario tests fail on declared-core regressions; docs distinguish engine guarantees from fixture/presentation choices.

**Validation:** Clean-host install test, scenario suite, generator suite, registry JSON parse, `git diff --check`.

---

## Task 11: UI Component Contract and Generated Resource States

**State:** Pending Gate 2 completion.

**Goal:** Establish reusable accessible component APIs for generated resource screens instead of relying on companion-only partials.

**Scope:** Define component inputs/events for list, form, show, filter, pagination, validation, authorization denial, loading, empty, success, disabled, and error states. Integrate responsive tables, status badges, filter persistence, association editors, and standard actions into engine rendering. Publish design tokens and enforce light/dark/system behavior.

**Acceptance criteria:** Generated index/new/edit/show work in all themes and operational states; tables/forms remain usable at mobile widths; non-text controls have accessible names/state and status is never color-only.

**Validation:** Component/view specs, generated-host system tests across themes, accessibility assertions, registry JSON parse, `git diff --check`.

---

## Task 12: Navigation, Admin Shell, and Theme Conformance

**State:** Pending generated-host proof; companion behavior exists.

**Goal:** Prove the engine-owned shell and resource navigation work for real hosts and large menus while retaining host layout replacement.

**Scope:** Finalize navigation item label, route, icon, active state, access-context visibility, and fallback contracts. Verify persisted desktop collapse and closed-by-default mobile drawer behavior across routes. Support menus of at least ten resources without overlap or horizontal strips.

**Acceptance criteria:** A generated host renders the default shell with multiple authorized resources; desktop persistence and mobile close-on-navigation/backdrop/Escape behavior pass at 1440px, 768px, and 390px; toggle names and `aria-expanded` state are correct.

**Validation:** Generated-host browser tests/screenshots, companion navigation regression, registry JSON parse, `git diff --check`.

---

## Task 13: Browser, Accessibility, and Visual Regression Policy

**State:** Pending Gate 2 completion.

**Goal:** Adopt a stable browser driver and repeatable visual/accessibility evidence with an explicit flake budget.

**Scope:** Select/document the system driver; add deterministic fixtures and screenshots for dashboard, list, new, edit, show, nested forms, navigation states, and mobile drawer in light/dark modes; add keyboard, focus, reduced-motion, touch-target, overflow, missing-icon, and primary-content checks.

**Acceptance criteria:** CI runs the browser suite within its documented flake budget; screenshots fail on meaningful layout/content/icon/overflow regressions; accessibility is verified for CRUD, filtering, navigation, associations, actions, and errors.

**Validation:** Browser/screenshot suite locally and CI, companion requests, snapshot process docs, `git diff --check`.

---

## Task 14: Compatibility Matrix and Release Automation

**State:** Pending Gate 2 completion.

**Goal:** Convert stated Rails/Ruby support into executable compatibility evidence.

**Scope:** Implement CI lanes for minimum, stable, latest, and preview Rails/Ruby combinations, including Rails 8.1.3 and Ruby 4. Test ERB/JSON constraints, installation, generated hosts, browser coverage where feasible, and documented bounds. Define support-window review, deprecation checks, and compatibility-failure handling.

**Acceptance criteria:** Every supported lane runs engine and generated-host suites; preview results follow the non-blocking policy; compatibility docs and gem constraints match CI evidence.

**Validation:** CI matrix evidence, dependency-resolution tests, docs/registry update, `git diff --check`.

---

## Task 15: Observability, Governance, and Operational Readiness

**State:** Pending Gate 1/Gate 2 completion.

**Goal:** Define the production-operational contracts for a security-sensitive admin engine.

**Scope:** Add correlation IDs, structured logs, metrics, tracing boundaries, alerts, and incident/runbook requirements. Define ADR templates, ownership, review/escalation, release approval, hotfix, rollback, retention, and compliance-export governance. Require tenant, field, audit, and AI redaction across logs and telemetry.

**Acceptance criteria:** Request/mutation/audit/AI traces correlate without sensitive leaks; required failures have alert/recovery paths; governance templates and release gates are executable repository artifacts.

**Validation:** Instrumentation/redaction tests, runbook/ADR review, registry JSON parse, `git diff --check`.

---

## Task 16: Beta Evidence Reconciliation and Release Decision

**State:** Pending gate, not a feature.

**Goal:** Make an honest beta decision from Rails-host evidence after Tasks 1-15 complete or are explicitly deferred with approved rationale.

**Scope:** Reconcile every Gate 1/Gate 2 row, each must-keep inventory item, registry claim, generated-host proof, and CI/browser result. Record open risks, accepted deferrals, owner, target release, and why a deferral does not invalidate the beta claim.

**Acceptance criteria:** No beta-blocking requirement is unassigned; registry/checkpoint/architecture/generator/security/UI/showcase docs agree; the outcome is explicit: hold, limited beta with exclusions, or approved beta.

**Validation:** Full required suite, generated-host suite, browser suite, compatibility evidence, registry JSON parse, docs review, `git diff --check`.

---

## Task 17: Import, Export, and Large Data Operations

**State:** Deferred until beta foundation completes.

**Goal:** Deliver tenant- and policy-safe import/export with preview, validation, masked fields, jobs, retries, and auditability.

**Acceptance criteria:** Mapping preview and row-level errors; role/field-masked export profiles; tenant-safe jobs; retry/idempotency; audit and browser/request proof.

---

## Task 18: Production AI Providers, Routing, and Trace Operations

**State:** Deferred until provider, audit, observability, and field-policy foundations complete.

**Goal:** Productionize the V1 read-only AI tasks with provider failures, redaction, asynchronous progress, uncertainty/fallback UX, searchable retained traces, and safe tool routing.

**Acceptance criteria:** Provider failures do not leak/broaden access; async lifecycle is visible and accessible; trace retention/redaction/search/export work; role/tenant/prompt-injection tests enforce safety; no mutation occurs without explicit approval policy.

---

## Task 19: AI V1.1

**State:** Deferred product work.

**Goal:** Add reviewable structured extraction, cross-record analysis, dashboard narratives, and reusable prompt templates.

**Acceptance criteria:** Results use authorized tenant-scoped data, expose rationale/evidence where applicable, persist only after review/confirmation, and are fully traced/audited.

---

## Task 20: AI V2

**State:** Deferred product work.

**Goal:** Add guided workflow copilots, policy-approved automation, and multi-source reasoning.

**Acceptance criteria:** Each tool call has actor/role/context traceability; approval/escalation gates prevent unapproved mutations; multi-source context preserves field allowlists and tenant isolation; recovery and incident tests exist.

---

## Task 21: Migration Tooling and 1.0 Release Guarantees

**State:** Deferred until beta outcomes establish the stable public API.

**Goal:** Let legacy Krudmin users migrate safely and establish 1.0 upgrade, deprecation, and release guarantees.

**Scope:** Publish a legacy-constant-to-new-API mapping including associations, actions, transitions, fields, and presentation. Build codemods/lints, migration warnings, justified shims, and an automated host checklist. Define migration guides, removal timelines, release governance, and showcase compatibility checks.

**Acceptance criteria:** A representative legacy resource, including `Car`/`Passenger` nested forms, migrates in under 30 minutes with automated verification; deprecations are actionable; release protocol and CI evidence meet the 1.0 gate.

---

## Coverage Ledger

| Source requirement | Owning task(s) |
| --- | --- |
| Generic secured CRUD and generated-host proof | 1, 9, 10 |
| Nested forms and association editors | 2 |
| Authentication, authorization, tenant, audit, notification providers | 3 |
| CSRF, sessions, cookies, headers, sensitive data, threat model | 3 |
| HTML, JSON, Turbo responses and durable audit | 4 |
| Eager loading, soft delete/archive, N+1 and query contract | 5 |
| Field-level decisions and consistent denial UI | 6 |
| Status transitions and custom actions | 7 |
| Dashboard lifecycle, visibility, and drill-down | 8 |
| Install/resource/action/dashboard/docs-sync generators and host registry | 9 |
| Generated showcase and scenario CI evidence | 10 |
| Component APIs, state treatments, themes, tables, forms | 11 |
| Admin shell, resource navigation, responsive sidebar | 12 |
| Stable browser driver, accessibility, screenshots, flake budget | 13 |
| Rails/Ruby support matrix and release automation | 14 |
| Logging, metrics, tracing, governance, runbooks, releases | 15 |
| Honest beta gate | 16 |
| Import/export | 17 |
| Production AI routing and trace operations | 18 |
| AI V1.1 capabilities | 19 |
| AI V2 automation capabilities | 20 |
| Legacy migration and 1.0 guarantees | 21 |

## Completion Rule

A task is complete only when its acceptance criteria, focused tests, documentation, registry status, and listed validation all pass. A task cannot be marked complete from implementation intent, a unit-only contract, or a companion-only demonstration when it requires generated-host or browser evidence.