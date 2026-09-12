# Beta Readiness Checkpoint and Session Handoff

Date: 2026-09-12

## Decision

**Hold beta.** KrudminAI has useful contract implementations, a runnable Rails demo host, and request-level evidence for a tenant-scoped CRUD workflow. It does not yet deliver the central product promise end to end: a resource declaration or generator output must supply generic secured CRUD, rendering, and response behavior without resource-specific host controllers or views.

This document supersedes the earlier checkpoint statement that the demo could not bundle or run locally. The compatibility bundle is now resolved in `demo/`; the companion host database prepares, seeds, serves, and passes its request suite. That is integration-reference evidence, not beta evidence.

## Product Boundary Learned From the Demo

The initial companion app was built too much like an ordinary Rails application: it had a manual `TicketsController`, `@ticket`/`@tickets`, ticket-specific route helpers, and ticket-specific form paths. This created duplicate plumbing and produced avoidable routing, layout, and browser failures.

The correct KrudminAI boundary is now partially implemented:

```ruby
class TicketsController < KrudminAI::ResourceController
  resource TicketsResource
end
```

```ruby
class TicketsResource < KrudminAI::Resources::Base
  model DemoTicket
  routes :tickets
  tenant_key :tenant
  permit :title, :description, :state, :priority, :assignee
end
```

`KrudminAI::ResourceController` now owns authentication-provider access, access-context construction, secure record lookup, canonical query composition, mutation dispatch, audit sink resolution, `model`/`models`, and generic route helpers. It explicitly renders the host `application` layout so host navigation and assets remain intact.

The demo no longer owns ticket resource templates. Engine-owned defaults render its index, new, edit, and show pages from resource labels and list/form/show metadata, while a host resource template remains an optional override. This is companion evidence only; a generated Rails host must still boot and exercise the same behavior before the generic CRUD beta blocker closes.

## Verified Current State

### Engine contracts

- `Resources::Base` supports resource model, tenant/policy scopes, record tenant access, mutation action authorization, direct `has_many` metadata, filters, sort/pagination, AI field allowlists, permitted attributes, tenant key, and route key.
- `QueryAccessPipeline` applies tenant scope, policy scope, filters, sort, then pagination.
- `MutationPipeline` supplies create/update/destroy authorization, record tenancy checks, result taxonomy, and transaction-aware audit hooks.
- `ResourceController` delivers normalized HTML, JSON, and Turbo Stream mutation responses through the response adapter; the demo request suite covers create success, validation failure, and scoped denial behavior.
- Hotwire/CSS primitives, dashboard widgets, showcase contracts, and read-only AI contracts exist.
- Install, resource, docs-sync, and showcase generator contracts exist. Resource generator output now targets the thin generic-controller pattern.

### Companion demo (`demo/`)

- Local path dependency on the engine; SQLite database and seeds.
- Session-selected demo users represent two tenants and support-agent/manager roles.
- `TicketsController` is a resource binding only.
- Ticket CRUD uses engine-owned templates and generic `model`, `models`, `collection_path`, `resource_path`, `new_resource_path`, and `edit_resource_path` helpers. Its direct `has_many` passenger editor proves nested create, validation retention, add/remove, and cross-tenant child-ID rejection in the companion only.
- The dashboard and companion pages are still demo-specific integrations.
- Audit events persist in the demo database; the local companion assistant makes no external provider calls.
- A live server can be started at `http://127.0.0.1:3000`.

### Latest validation evidence

| Check | Result |
| --- | --- |
| Resource generator contract spec | `2 examples, 0 failures` |
| Demo ticket integration suite | `7 runs, 75 assertions, 0 failures, 0 errors, 0 skips` |
| Capability registry JSON | Parses successfully |
| `git diff --check` | Clean at last run |
| Browser inspection after layout fix | Fresh authenticated session confirmed host header, navigation, stylesheet, and ticket edit form render at `/tickets/7/edit` |

The shared browser automation bridge has intermittently timed out while dispatching native clicks after server restarts, even for visible enabled controls. Do not classify that alone as an application failure. Do classify it as a test-infrastructure limitation until a clean system-test driver policy and stable browser suite exist.

## Reconciliation With the Original Prompt Pack

The original sequence in [krudminai_kickoff_prompt_pack.md](krudminai_kickoff_prompt_pack.md) was broadly sound. Its problem was that contract-first work remained disconnected from a generated Rails host too long.

| Original recommended slice | Current status | Recommendation |
| --- | --- | --- |
| Bootstrap, compatibility, CI, docs-sync | Partial | Keep. Compatibility is demonstrated in the demo bundle, but the engine's full bundled suite and CI matrix need reproducible execution evidence. |
| Resource query/access pipeline | Implemented contract; partial Rails evidence | Keep and harden through generated-host request/system tests. |
| Mutation pipeline and response contract | Implemented contract; partial delivery | Complete controller integration for HTML, JSON, and Turbo before calling it beta-ready. |
| Hotwire UI foundations | Implemented primitives; not resource-integrated | Move generic CRUD rendering to engine templates/components. Keep host overrides explicit. |
| Install/resource/docs-sync generators | Partial | Run generator output in a disposable Rails host and test re-runs, namespaces, inflections, and collision behavior. |
| Dashboards/widgets | Partial | Preserve as a later slice after generic CRUD; add resource-aware scoped drill-downs and UI authorization. |
| Showcase generator | Partial | Make it boot and execute workflows in CI, rather than only verify manifests/docs. |
| In-app assistant | Partial | Maintain read-only policy and defer provider-backed production work until persistent redacted traces and provider contracts exist. |
| Beta checkpoint | Complete, revised here | Keep beta on hold until the blocking items below close. |

## Gate Assessment

### Gate 1: Required before coding starts

| Area | Status | Gap |
| --- | --- | --- |
| Product scope and personas | Partial | Exit criteria and acceptance criteria per release phase are incomplete. |
| Authentication | Partial | Demo adapter works; session lifetime, idle timeout, MFA readiness, recovery, and provider validation are unspecified. |
| Authorization | Partial | Query/mutation policies deny by default; field-level decisions and standardized UI denial behavior are absent. |
| Provider contracts | Partial | Configuration has callables, but signatures, lifecycle, errors, boot validation, and adapter conformance tests are absent. |
| Multi-tenancy | Partial | Row-level tenant behavior works in the demo; supported models, super-admin rules, and request-resolution policy are absent. |
| Query/data access | Partial | Canonical order is implemented; eager loading, archival/soft delete, and N+1 rules are absent. |
| Dashboards | Partial | Core widgets scope data; lifecycle, widget visibility, and secure generic drill-down links are incomplete. |
| Showcase | Partial | Blueprint and verifier exist; generated showcase boot and end-to-end scenarios are not proven. |
| UI/theming | Partial | Tokens/theme module/primitives exist; generic CRUD integration, component states, token dictionary, dark-mode proof, and interaction targets are incomplete. |
| Security baseline | Missing | Threat model; CSRF, cookie, session, header, sensitive-data, export/logging, and incident policies are absent. |
| Generator contracts | Partial | Contract specs pass; generated application execution and merge/collision behavior are incomplete. |
| AI coding-agent integration | Partial | Instructions and docs sync exist; resource/action/dashboard recipes and conformance enforcement are incomplete. |
| In-app AI interaction | Partial | Scoped read-only contracts exist; provider failure behavior, redaction policy, durable trace semantics, and production UI routing are incomplete. |
| Capability registry | Partial | Engine registry exists; per-host generated bindings, flags, lifecycle, and release metadata are incomplete. |
| Compatibility policy | Partial | Bounds exist and demo works; all supported Rails/Ruby CI lanes are unverified. |
| Governance | Missing | ADR template, ownership, review, release, and escalation process are absent. |

### Gate 2: Required before beta

| Area | Status | Gap |
| --- | --- | --- |
| API/responses | Partial | Controller-level HTML/JSON/Turbo behavior and query parameter response contracts need real request coverage. |
| Component contract | Missing | Component APIs/events, loading/empty/error states, keyboard/touch checks, and visual consistency tests are absent. |
| Audit/compliance | Partial | Demo persistence exists; engine needs durable transaction/outbox semantics, retention, redaction, access control, and export. |
| Showcase distribution | Partial | Generator exists; booted demo mode, version lockstep, and CI walkthroughs are absent. |
| Import/export | Missing | No design or implementation. |
| Testing/quality | Partial | Unit and request slices exist; test pyramid, system driver policy, browser flake budget, and coverage targets are absent. |
| Performance/scalability | Missing | No SLOs, caching/job policy, or UX performance measurement. |
| Observability | Missing | No correlation IDs, structured logging schema, metrics, or tracing. |
| Agent action traces | Partial | Demo persists a trace; engine retention/redaction/search/export and mutation-result protocol are absent. |
| Conversational routing | Partial | Fixed read-only task routing exists; async progress, fallback, uncertainty, and provider failure behavior are absent. |
| CI matrix | Partial | Matrix scaffold exists but does not demonstrate browser, generated-host, performance, or compatibility execution. |

## Beta Blockers and Risks

1. **Generated-host CRUD proof is incomplete.** Engine-owned generic rendering is proven in the companion, but generated-host boot, routes, and request/system evidence are still absent.
2. **Providers are informal.** Callable configuration can silently misbehave and lacks boot-time validation or contract tests.
3. **Generated-host audit evidence is incomplete.** The companion proves transactional audit rollback and retry behavior; an independently generated Rails host must prove the same contract.
4. **Full format delivery is unproven.** HTML is covered in the generic controller; JSON and Turbo response adapters are not wired through it in request tests.
5. **Security baseline is undocumented.** The absence of defined session, CSRF, header, cookie, and data-masking policy blocks beta claims.
6. **Generated applications are not the test target.** Generator unit tests are not proof that generated code boots, routes, renders, and authorizes correctly.
7. **Browser confidence is incomplete.** There is no stable, repeatable system suite for navigation, filtering, edit/create/destroy, focus behavior, themes, and Turbo interactions.

## Next Session: Exact Starting Point

Start with this slice, not a new dashboard, showcase, or AI feature:

### Slice 1: Generic Resource Delivery and Generated-Host Conformance

**Goal:** A host declares a resource and routes it conventionally; KrudminAI provides the secured controller behavior and default list/new/edit/show form rendering. No model-specific controller action, instance variable, route helper, or template should be required for standard CRUD.

**Scope:**

- Extend `Resources::Base` with minimal presentational metadata: label, list fields, form fields, and show fields. Do not introduce a broad field-type framework unless required by the first generic renderer.
- Add engine-owned generic templates/partials or components for index, form, and show using `model`, `models`, and generic route helpers.
- Make generated resources use those defaults. Preserve host templates as intentional overrides.
- Update the demo to remove or reduce `demo/app/views/tickets/*` to only a documented optional override, preferably deleting them if defaults cover the demo fields.
- Add a disposable/generated Rails-host integration test that proves anonymous redirect, tenant list scope, cross-tenant `404`, permitted create/update/destroy, audit emission, host layout/assets, and route helpers.
- Do not add dashboards, custom actions, transitions, provider redesign, or new AI capabilities in this slice.

**Acceptance criteria:**

1. A generated `OrdersResource` plus a thin `OrdersController` boots in a Rails host with `resources :orders`.
2. Default engine views render index/new/edit/show without host resource templates.
3. The default form uses the resource permit list and generic route helpers.
4. The layout and engine/host stylesheet contract are present in the HTTP response.
5. Request tests prove security and CRUD behavior across at least two tenants and two roles.
6. A focused browser/system test covers at least list -> edit -> submit using the selected stable driver.

**Likely files to inspect first:**

- [lib/krudmin_ai/resource_controller.rb](../lib/krudmin_ai/resource_controller.rb)
- [lib/krudmin_ai/resources/base.rb](../lib/krudmin_ai/resources/base.rb)
- [lib/krudmin_ai/generators/resource_contract.rb](../lib/krudmin_ai/generators/resource_contract.rb)
- [demo/app/resources/tickets_resource.rb](../demo/app/resources/tickets_resource.rb)
- [demo/app/views/tickets](../demo/app/views/tickets)
- [demo/test/integration/ticket_access_test.rb](../demo/test/integration/ticket_access_test.rb)

### Slice 2: Provider Contracts and Security Baseline

Define executable authentication, authorization, tenant, audit, and notification adapter interfaces. Validate config at boot, fail closed with clear errors, ship test adapters, and document the CSRF/session/cookie/header/sensitive-data threat model.

### Slice 3: Format Delivery and Durable Audit

Wire `MutationResponseAdapter` through `ResourceController` for HTML, JSON, and Turbo Stream. Introduce a transaction-aware audit persistence/outbox contract and test failure/recovery behavior in Rails.

### Deferred After Those Slices

1. Dashboard drill-down/rendering integration and field-level authorization.
2. Showcase generated-host boot plus role/tenant walkthroughs in CI.
3. Browser test policy, accessibility state coverage, visual regression strategy, and theme verification.
4. Import/export, observability, performance SLOs, governance, and production AI provider integration.

## Resume Commands

From the repository root:

```sh
cd /Users/mamerced/projects/KrudminAI

# Focused generator contract
ruby -Ilib -S rspec spec/lib/krudmin_ai/generators/resource_contract_spec.rb

# Current companion security/CRUD coverage
BUNDLE_GEMFILE=/Users/mamerced/projects/KrudminAI/demo/Gemfile \
  "$HOME/.rvm/gems/ruby-4.0.6/wrappers/bundle" exec \
  demo/bin/rails test demo/test/integration/ticket_access_test.rb

# Start the companion app
BUNDLE_GEMFILE=/Users/mamerced/projects/KrudminAI/demo/Gemfile \
  "$HOME/.rvm/gems/ruby-4.0.6/wrappers/bundle" exec \
  demo/bin/rails server -p 3000

# Hygiene checks
ruby -rjson -e 'JSON.parse(File.read("docs/capability_registry.json"))'
git diff --check
```

The demo seed users are Morgan Lee (`northwind`, support agent), Avery Patel (`northwind`, manager), and Jordan Kim (`southwind`, support agent). Use them to verify tenant and role behavior.

## Documentation Maintenance Required in the Next Slice

Update this checkpoint, [architecture.md](architecture.md), [generators.md](generators.md), [capability_registry.json](capability_registry.json), and the relevant contract guide in the same change as any capability work. Do not mark a capability as fully implemented until it is exercised through a Rails host, not solely a fake-relation or unit-contract test.
