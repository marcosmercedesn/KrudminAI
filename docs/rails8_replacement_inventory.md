# KrudminAI Replacement Inventory

Date: 2026-09-11

## Purpose

This document inventories what to keep, what to replace, and what an AI coding agent needs to generate a modern successor to Krudmin with first-class compatibility for Rails 8.1.3 and Ruby 4, plus a forward upgrade path for future Rails and Ruby versions.

## Forefront Product Pillars

These requirements are first-class and must shape architecture, generators, defaults, and documentation from day one.

1. Admin panel first
- KrudminAI is primarily for admin panels and back-office CRUD systems.
- Default scaffolds must optimize for authenticated operator workflows, not public site patterns.

2. Authentication and security by default
- Authentication is required by default for all generated admin resources.
- Generated controllers should include authentication guards by default.
- Security-sensitive defaults are mandatory: CSRF protection, secure session handling, auditability, and safe failure behavior.

3. Authorization as a core contract
- Authorization is not optional in core flows; every resource query path must pass through policy scope.
- Generated resource and action scaffolds must include explicit policy predicates and deny-by-default behavior.
- UI affordances (buttons, links, widgets) must reflect authorization decisions consistently.

4. Dashboards and summarization are pivotal
- Dashboard capability is core, not an add-on.
- Widget pipelines must be policy-aware and tenancy-aware.
- First-party widget types must include count, table, and summary widgets suitable for operational monitoring.

5. Multi-tenancy and multi-role support
- Tenant and role boundaries are first-class concerns for authenticated users.
- Data isolation must be enforced in query composition and authorization layers.
- Generators and docs must include patterns for organization-scoped access and role-based permissions.

6. Showcase admin panel for demonstration and learning
- KrudminAI must ship with a generated example admin panel that demonstrates core and advanced capabilities end to end.
- The showcase must be useful for two audiences: product teams evaluating the platform and AI coding agents learning implementation patterns.
- The showcase must include realistic domain scenarios, not toy-only examples.

7. In-app conversational AI interface
- KrudminAI must provide a built-in prompt interface where authenticated users can interact with app data and workflows in natural language.
- The conversational interface must enforce the same role, policy, and tenant boundaries as the standard UI.
- AI responses must be traceable, explainable, and auditable at the record and action level.

8. Premium UI and UX quality bar
- KrudminAI must target consumer-grade smoothness for core interactions: navigation, filtering, editing, dashboard drill-downs, and conversational AI workflows.
- Visual and interaction quality must feel intentional and polished, with consistent spacing, typography, hierarchy, and feedback states.
- Motion and transitions must be meaningful, subtle, and fast, never decorative noise or blocking friction.
- Keyboard, screen reader, and reduced-motion support are mandatory and must not be degraded by visual polish.

## Security-First Defaults For KrudminAI

1. Generated admin controllers require authentication by default.
2. All index/list/search/dashboard relations must be tenant-scoped and policy-scoped.
3. Every mutation endpoint must perform explicit authorization checks.
4. Default audit hooks for sensitive actions: create, update, destroy, transition, custom actions.
5. Session and cookie guidance must include secure defaults for production.

## Dashboard and Access Control Contract

1. Widget data sources must originate from authorized, tenant-scoped resource relations.
2. If a user cannot access a resource index, related widgets are hidden or denied.
3. Summary widgets must not leak cross-tenant aggregates.
4. Drill-down links from widgets must preserve scope constraints.

## In-App AI Capabilities Catalog

This catalog defines the product-facing AI capabilities KrudminAI should expose inside admin panels.

### V1 capabilities (required)

1. Record summary
- Summarize a selected record using only authorized, tenant-scoped fields.
- Include confidence and evidence references to source fields.

2. Record Q and A
- Let users ask questions about a selected record.
- Restrict answers to data the user can access through policy and tenant scope.

3. Document summary
- Summarize uploaded or attached documents.
- Support short, medium, and detailed summary modes.

4. Report insight hints
- Explain notable trends from dashboard widgets and report tables.
- Suggest next filters or drill-down paths without mutating data.

5. Suggested next actions
- Propose potential workflows or state transitions.
- Default to suggestion-only mode unless explicit approval policy allows execution.

### V1.1 capabilities (high-priority follow-up)

1. Structured extraction
- Extract typed fields from documents into a reviewable draft.
- Require user confirmation before saving extracted values.

2. Cross-record analysis
- Compare related records for anomalies, duplicates, or inconsistencies.
- Return ranked findings with rationale.

3. Dashboard narrative mode
- Generate plain-language weekly or monthly operational summaries.
- Include role-aware and tenant-safe KPI commentary.

4. Prompt templates
- Ship reusable templates per use case: compliance review, support triage, finance exceptions, CRM account health.

### V2 capabilities (advanced)

1. Guided workflow copilots
- Multi-step assistants that gather missing inputs and prepare actions.
- Enforce approval and escalation policies before execution.

2. Agent-assisted automation
- Allow approved AI tasks to trigger background workflows.
- Require full traceability and policy checks for each tool call.

3. Multi-source reasoning
- Analyze combined data from records, documents, and dashboards.
- Preserve strict field allowlists and tenant isolation across sources.

## AI Capability Safety Boundaries

1. Same permissions as user
- In-app AI can only access what the current authenticated user can access.

2. Default read-only interaction
- AI analysis is non-destructive by default.

3. Controlled mutation path
- Any AI-proposed mutation requires explicit approval gates and auditable confirmation.

4. Traceability
- Every AI interaction logs actor, prompt, context policy, model, output, and resulting actions.

5. Redaction and data minimization
- Prompt context must apply field allowlists and sensitive-data masking before provider calls.

## Specification Gates

Use these gates as mandatory checkpoints so coding starts with clear expectations and ships with fewer regressions.

### Gate 1: Required Before Coding Starts

1. Product scope specification
- Define v1, v1.1, and v2 scope boundaries.
- Define explicit non-goals for each phase.
- Define primary personas: admin, manager, auditor, support operator.

2. Authentication specification
- Define default authentication provider and extension points.
- Define session lifetime, idle timeout, and remember-me rules.
- Define MFA readiness requirements and account recovery expectations.

3. Authorization specification
- Define resource-level, action-level, and field-level authorization requirements.
- Define deny-by-default behavior and fallback responses.
- Define UI authorization behavior: hide, disable, or explain.

4. Provider contracts specification
- Define first-class provider contracts for authentication, authorization, tenant resolution, audit logging, and notifications.
- Define provider lifecycle hooks and failure behavior.
- Define contract tests required for any custom provider implementation.

5. Multi-tenancy specification
- Define supported tenancy model(s): row-level, schema-level, or hybrid.
- Define tenant resolution in request lifecycle.
- Define super-admin and cross-tenant access constraints.

6. Query and data access specification
- Define canonical query order: tenant scope, policy scope, filters, sort, paginate.
- Define eager-loading conventions and N+1 prevention rules.
- Define soft-delete and archival behavior.

7. Dashboard specification
- Define widget lifecycle: query, authorize, summarize, render, drill-down.
- Define first-party widget catalog for v1.
- Define anti-leakage rules for aggregates.

8. Showcase admin panel specification
- Define mandatory showcase modules that exercise CRUD, search, filters, inline editing, transitions, custom actions, dashboards, audit trail, and role/tenant scoping.
- Define sample personas and seed data profiles used by the showcase.
- Define scenario packs for common system archetypes such as CRM, support desk, inventory ops, and compliance operations.
- Define walkthrough flows for common scenarios so AI agents can map intent to implementation patterns.
- Define acceptance tests that verify showcase behavior remains aligned with engine capabilities.

9. UI, theming, and dark mode specification
- Define first-class light, dark, and system mode behavior.
- Define design-token dictionary and naming conventions.
- Define accessibility baseline for both themes.
- Define interaction design primitives: focus states, hover/active/pressed states, loading and skeleton states, and empty-state behavior.
- Define motion system rules: durations, easings, choreography, reduced-motion fallback, and interruption-safe transitions.
- Define UX latency targets for key interactions: first response feedback, filter apply, inline save, modal open/close, and dashboard widget refresh.

10. Security baseline specification
- Define threat model for admin-panel attack surfaces.
- Define secure defaults for CSRF, sessions, cookies, and headers.
- Define sensitive-data handling rules for UI, exports, and logs.

11. Generator contract specification
- Define exact output files per generator.
- Define idempotency and re-run behavior.
- Define merge behavior when target files already exist.

12. AI coding agent integration specification
- Define required AI instruction and docs artifacts in host apps.
- Define agent-safe coding constraints and guardrails.
- Define prompt recipes for resource, custom action, and dashboard workflows.

13. In-app AI interaction specification
- Define supported in-app AI tasks for v1: summarize record, ask questions about a record, summarize document, analyze report, and suggest next actions.
- Define conversation context building rules with field allowlists, redaction, and tenant scoping.
- Define action boundaries between read-only suggestions and mutation-capable workflows.
- Define required human approval gates for sensitive or destructive operations.

14. Capability registry specification
- Define a machine-readable capability manifest generated per app and per release.
- Include enabled modules, provider bindings, feature flags, and compatibility metadata.
- Use this manifest as input for AI agents and automated conformance checks.

15. Compatibility policy specification
- Define support window policy for Rails and Ruby versions.
- Define versioning and deprecation policy.

16. Governance kickoff specification
- Define architecture decision record process and templates.
- Define subsystem ownership and maintainer responsibilities.

### Gate 2: Required Before Beta

1. API and response specification
- Define normalized response envelopes for HTML, JSON, and Turbo Stream.
- Define error taxonomy and status-code mapping.
- Define pagination/filter/sort parameter contract.

2. Component contract specification
- Define required v1 component APIs and events.
- Define component states: loading, empty, error, success.
- Define component accessibility checklist.
- Define UI consistency checks for spacing, typography scale, and state behavior across components.
- Define interaction acceptance checks for focus handling, keyboard traversal, and touch target size.

3. Audit and compliance specification
- Define required events and metadata for audit trails.
- Define retention, redaction, and access controls.
- Define compliance export/report format.

4. Showcase packaging and distribution
- Define a generator mode that installs the showcase app or module set into a host app.
- Define a lightweight demo mode for local trials and documentation screenshots.
- Define versioning policy so showcase examples stay in lockstep with engine releases.

5. Import/export and data operations specification
- Define import mapping flow with preview and row-level validation reports.
- Define export profiles with role-based field masking and tenant boundaries.
- Define background processing and retry behavior for large imports/exports.

6. Testing and quality specification
- Define required test pyramid coverage by feature category.
- Define mandatory contract tests for generators and authorization behavior.
- Define browser/system test driver policy and flake budget.

7. Performance and scalability specification
- Define SLOs for index, search, and dashboard pages.
- Define thresholds for background-job offloading.
- Define caching strategy and invalidation boundaries.
- Define front-end responsiveness budgets for perceived smoothness (interaction-to-feedback, transition completion, and frame stability during list and dashboard updates).
- Define measurement protocol for UX smoothness in CI and staging (representative hardware profiles and network conditions).

8. Observability specification
- Define structured logging schema and correlation IDs.
- Define required metrics and dashboards.
- Define tracing boundaries for query and mutation pipelines.

9. Agent action trace specification
- Define trace schema for AI-assisted actions: actor identity, role, prompt context, tools used, decision output, and resulting data mutations.
- Define retention and redaction policies for agent traces.
- Define searchable export paths for incident response and compliance reviews.

10. Conversational interface and tool routing specification
- Define in-app chat UI behavior, intent routing, and tool invocation lifecycle.
- Define confidence and uncertainty signaling requirements in responses.
- Define fallback behavior when AI services fail or return unsafe outputs.
- Define asynchronous execution and progress updates for long-running AI analysis tasks.

11. CI matrix specification
- Define minimum, stable, latest, and preview lanes for Rails/Ruby.

### Gate 3: Required Before 1.0 Release

1. Upgrade and migration guarantees
- Publish migration guide requirements for every release.
- Define deprecation message format and removal timelines.
- Provide migration lints or codemods for legacy adopters.

2. Release governance
- Define release-gate checklist and sign-off process.
- Define breaking-change review policy.
- Define compatibility verification protocol per release.

3. AI reliability guarantees
- Define validation rules for AI-generated pull requests.
- Define conformance checks against auth/authz/tenancy contracts.
- Define docs-sync requirements so host-app AI context remains current.

4. Policy-safe automation guarantees
- Define required static and runtime checks that fail CI when policy_scope, tenant scope, or authorization checks are missing.
- Define required checks for unsafe raw queries in resource listing and dashboard pipelines.
- Define required checks for unauthorized data fields in exports.

5. Conversational safety and reliability guarantees
- Define required checks preventing in-app AI from exposing unauthorized fields, records, or tenant data.
- Define required checks preventing mutation execution without explicit approval policies.
- Define test scenarios for prompt injection resistance and unsafe tool-call blocking.

6. Showcase reliability guarantees
- Define showcase conformance checks against all documented core capabilities.
- Define release criteria requiring showcase walkthroughs to pass in CI.
- Define compatibility checks proving showcase works across supported Rails/Ruby matrix lanes.

7. Operational readiness
- Define alerting thresholds and incident response expectations.
- Define runbooks for auth failures, policy denials, and data-scope incidents.
- Define rollback and hotfix expectations for security-critical defects.

8. UI/UX release quality guarantees
- Define release gates that require usability walkthroughs for CRUD, search, dashboard, and conversational AI flows.
- Define regression checks for interaction smoothness, visual consistency, and accessibility parity across light and dark modes.
- Define acceptance criteria for polish defects that block release versus defer to patch releases.

## Current System Strengths

1. Strong resource metadata pattern
- Resource behavior is centralized with constants and predictable defaults in [lib/krudmin/resource_managers/base.rb](lib/krudmin/resource_managers/base.rb#L16).
- Custom actions already have validation and route resolution heuristics in [lib/krudmin/resource_managers/base.rb](lib/krudmin/resource_managers/base.rb#L51).

2. Productive CRUD controller surface
- One base controller exposes index/new/create/edit/update/show/destroy plus transition support in [app/controllers/krudmin/application_controller.rb](app/controllers/krudmin/application_controller.rb#L16).
- Response formats include HTML, JSON, and Turbo Stream paths in [app/controllers/krudmin/application_controller.rb](app/controllers/krudmin/application_controller.rb#L22).

3. Mature search and filtering behavior
- Search persistence and cookie-backed filter state are implemented in [app/controllers/concerns/krudmin/searchable.rb](app/controllers/concerns/krudmin/searchable.rb#L7).
- Ransack-centric search architecture is documented in [docs/search_and_filtering.md](docs/search_and_filtering.md#L3).

4. Good extension and generator story
- Install/resource/field/custom_action/dashboard/state_machine generators exist under [lib/generators/krudmin](lib/generators/krudmin).
- Host-app documentation sync workflow exists via docs-only install mode in [docs/generators.md](docs/generators.md#L33).

5. Documentation as operational contract
- The architecture and behavior docs are broad and usable in [docs/architecture.md](docs/architecture.md#L1) and [docs/getting_started.md](docs/getting_started.md#L1).

## Current System Weaknesses and Aging Areas

1. jQuery-era dependency chain is still core
- Runtime dependencies include jquery-rails and momentjs-rails in [krudmin.gemspec](krudmin.gemspec#L23).
- Engine load path requires jquery-rails and momentjs-rails in [lib/krudmin/engine.rb](lib/krudmin/engine.rb#L2).
- UI controllers still wrap Select2 and daterangepicker jQuery plugins in [app/assets/javascripts/krudmin/controllers/select2_controller.js](app/assets/javascripts/krudmin/controllers/select2_controller.js#L1) and [app/assets/javascripts/krudmin/controllers/datepicker_controller.js](app/assets/javascripts/krudmin/controllers/datepicker_controller.js#L1).

2. Legacy asset composition model
- AssetBuilder concatenates many vendor/global scripts into one bundle in [lib/krudmin/asset_builder.rb](lib/krudmin/asset_builder.rb#L6).
- Vendored files include select2, daterangepicker, sweetalert, and custom globals in [app/assets/javascripts/krudmin/vendor](app/assets/javascripts/krudmin/vendor).

3. Test stack includes legacy browser tooling
- Poltergeist remains configured in [spec/rails_helper.rb](spec/rails_helper.rb#L2).

4. Known modernization debt already called out
- Roadmap still tracks factory_girl generator reference, Poltergeist removal, and jQuery removal in [docs/roadmap.md](docs/roadmap.md#L189).

5. Rails baseline messaging is outdated for new adopters
- Getting started still states Rails 5.1+ and Ruby 3.x+ in [docs/getting_started.md](docs/getting_started.md#L7).

## Replacement Target: KrudminAI

### Compatibility and architecture constraints

1. First-class compatibility with Rails 8.1.3 and Ruby 4.
2. Forward-compatible version policy and CI matrix that tracks minimum, stable, latest, and preview Rails/Ruby lanes.
3. No jQuery runtime dependency.
4. Hotwire-first interaction model with Turbo + Stimulus.
5. Propshaft-native assets and module-based JavaScript.

### Must-keep capabilities

1. Resource metadata configuration layer.
2. CRUD + search + sorting + pagination.
3. Authorization hooks (Pundit policy + policy_scope path).
4. Status transitions and custom actions.
5. Nested forms and association editors.
6. Dashboard widgets built from authorized resource scopes.
7. Audit trail extension points.

## AI Agent Generation Inventory

An AI coding agent needs the following inputs to generate a clean replacement consistently.

### A. Product contract files (mandatory)

1. System manifesto
- Scope boundaries, non-goals, supported Rails/Ruby versions, browser support policy.

2. Behavior contract
- Resource lifecycle semantics.
- Search operator contract.
- Authorization contract: every query must pass policy_scope.
- Custom action contract: declaration, route shape, policy predicate mapping.

3. UI contract
- Accessibility baseline, keyboard-first interactions, visual density requirements.
- Turbo Frame and Turbo Stream conventions.

4. Data contract
- Required model capabilities for nested relationships.
- Transition/state-machine semantics.
- Audit event envelope structure.

5. Migration contract
- Mapping table from current ResourceManager constants to new API.
- Deprecation timeline and fallback shims.

### B. Code generation primitives (mandatory)

1. Install generator
- Creates initializer, docs, AI instruction file, and starter directories.

2. Resource generator
- Creates resource config, controller, routes, policy stub, and request/system tests.

3. Action generator
- Creates custom member action route/controller/test scaffolding.

4. Field generator
- Creates field adapter, presenter/component partial, test scaffold.

5. Docs sync generator mode
- Updates docs in host app only for upgrade-safe AI context refresh.

### C. Runtime architecture primitives (mandatory)

1. Query pipeline
- Resource relation builder -> policy_scope -> filters -> sort -> pagination.

2. Presentation pipeline
- Field adapters with deterministic rendering per context: form/list/show/search/json.

3. Mutation pipeline
- Command handlers for create/update/destroy/transition/custom action with unified result envelope.

4. Event pipeline
- Turbo Stream event naming and payload conventions.

5. Error pipeline
- Validation and authorization errors map to consistent Turbo/HTML/JSON responses.

### D. Frontend modernization primitives (mandatory)

1. Replace Select2
- Adopt Tom Select or similar non-jQuery component with Stimulus wrapper.

2. Replace daterangepicker
- Adopt flatpickr or similar non-jQuery date/datetime picker.

3. Remove global utility coupling
- Convert global functions to Stimulus services/modules.

4. Remove vendored UMD assumptions
- Use ESM modules and import maps or jsbundling-rails strategy.

### E. Testing and quality primitives (mandatory)

1. Replace Poltergeist with Cuprite or Selenium.
2. Add contract tests for generator outputs.
3. Add compatibility tests for Rails 8.1.x and Ruby 4.
4. Add performance budget checks for index/search pages.

### F. AI-specific delivery assets (mandatory)

1. AI instruction file template in host app root.
2. Installable docs package under docs/engine_name.
3. Scenario recipes for common builds: CRM, ERP-lite, membership, content moderation.
4. Decision logs that record chosen defaults and rejected alternatives.
5. Showcase admin panel blueprint and walkthrough scripts for human and AI onboarding.
6. Machine-readable capability registry emitted by generators and updated on release.
7. Agent conformance playbooks for policy-safe changes and common remediation steps.

### G. In-app AI assistant assets (mandatory)

1. Conversational assistant blueprint with prompt UX patterns.
2. Task templates for record summary, document summary, report insight, and guided Q and A.
3. Tool routing contract that maps intents to scoped data actions.
4. Safety policy templates for approval gates, field redaction, and blocked operations.
5. End-to-end tests validating role, policy, and tenant-safe conversational behavior.

## Migration Work Breakdown

### Phase 1: Extraction and stabilization

1. Freeze current feature set and write parity tests.
2. Define replacement public API and compatibility table.
3. Remove known legacy blockers in tests and generators.

### Phase 2: New core runtime

1. Build resource/query/mutation pipelines in a new namespace.
2. Implement Turbo-first controllers and view components.
3. Implement non-jQuery form/search widgets.

### Phase 3: Generators and docs system

1. Rebuild install and resource generators against the new API.
2. Ship docs-only sync mode as first-class upgrade path.
3. Add AI-ready templates and scenario packs.

### Phase 4: Migration tooling

1. Create codemods for old ResourceManager constants.
2. Add deprecation warnings and migration lints.
3. Provide host-app migration checklist with automated verification task.

## Is an Admin Framework Still Worth It in the AI Era?

Short answer: yes, for repeated CRUD-heavy systems.

### Why framework + AI beats prompt-only in most teams

1. Consistency and policy safety
- Framework contracts prevent drift in auth, search semantics, and audit behavior.

2. Lower operational variance
- Prompt-only generation can differ by run, model, and tool version.

3. Faster onboarding
- New teams can scaffold with reliable defaults and avoid architectural re-decisions.

4. Better governance
- You can enforce constraints centrally and update docs/AI instructions in one place.

### When prompt-only can be enough

1. One-off internal tools with short lifespan.
2. Very small scope where generated inconsistency is acceptable.
3. Teams with strong senior review capacity and low compliance demands.

### Recommended strategy

Use a hybrid model:

1. Maintain a slim modern framework core as the guardrail layer.
2. Let AI agents generate domain features on top of those contracts.
3. Keep docs installable into host apps so AI agents always read local source-of-truth behavior.

## Acceptance Criteria for the Replacement

1. Zero jQuery dependencies in runtime and test stack.
2. End-to-end Turbo + Stimulus flows for CRUD/search/transitions.
3. CI matrix is green for minimum, stable, latest, and preview Rails/Ruby lanes, including Rails 8.1.3 and Ruby 4.
4. Generator outputs pass contract tests.
5. Host-app docs and AI instruction files are installable and syncable.
6. Migration guide converts an existing Krudmin resource in under 30 minutes.
7. UX quality gates pass for keyboard accessibility, reduced-motion support, and defined smoothness/latency budgets across CRUD, dashboard, and in-app AI flows.
