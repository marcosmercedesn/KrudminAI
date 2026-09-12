# Beta Readiness Checkpoint

Date: 2026-09-12

## Recommendation

**Hold beta.** KrudminAI has green, dependency-free contract coverage for its core query, mutation, dashboard, generator, showcase, UI-foundation, and AI boundaries. It does not yet provide the provider integrations, security baseline, Rails request integration, or operational specifications required to demonstrate those contracts in a host application.

## Validation Snapshot

The dependency-free contract suite passes with 33 examples and the JavaScript suite passes with 3 tests. Ruby syntax checks, capability registry parsing, `bin/verify_showcase`, and `git diff --check` also pass.

`bundle exec rspec` and `bundle exec rubocop` remain blocked locally before execution because the installed Ruby environment has ERB 6 only, while the Rails 8.1 compatibility policy currently requires `erb >= 4.0, < 6.0`. No dependency installation was performed during this checkpoint.

## Gate 1: Before Coding Starts

| Item | Status | Evidence and Remaining Gap |
| --- | --- | --- |
| Product scope | Partial | [product_scope.md](product_scope.md) defines versions, personas, and non-goals. Acceptance criteria and per-phase exit criteria are absent. |
| Authentication | Partial | Generated controllers require `authenticate_user!`, but no provider contract, session/MFA/recovery policy, or host integration exists. |
| Authorization | Partial | Resource policy scope and mutation predicates deny by default. Field-level UI authorization and standardized denial presentation are absent. |
| Provider contracts | Partial | [provider_contracts.md](provider_contracts.md) is descriptive; executable authentication, authorization, tenant, audit, and notification provider interfaces are absent. |
| Multi-tenancy | Partial | Tenant-first query/mutation checks are implemented. Supported tenancy models, request resolution, super-admin constraints, and cross-tenant policy are not specified. |
| Query and data access | Partial | Canonical query order is implemented and tested. Eager loading, soft deletion, archival, and N+1 conventions are not specified. |
| Dashboard | Partial | Count, table, and summary widgets apply tenant and policy scope. Widget lifecycle, authorization-driven hide/deny behavior, and scoped drill-downs are not implemented. |
| Showcase | Partial | Generator, migrations, seed data, walkthroughs, and a manifest exist. It is not booted in a test host and depends on host integration glue. |
| UI, theming, dark mode | Partial | CSS tokens, three primitive partials, theme controller, visible focus, and reduced-motion fallback exist. A token dictionary, loading/empty/error states, motion rules, and latency targets are missing. |
| Security baseline | Missing | No threat model or policy for CSRF, sessions, cookies, headers, UI/export/log masking, or security incident handling. |
| Generator contracts | Partial | Install, resource, docs-sync, and showcase contracts have idempotency tests. Merge rules, collision behavior, attribute inference, and generated-app execution are incomplete. |
| AI coding-agent integration | Partial | Root and generated `AGENTS.md`, docs sync, and showcase agent guidance exist. Resource/action/dashboard prompt recipes and conformance enforcement are incomplete. |
| In-app AI interaction | Partial | Four read-only tasks, allowlisted scoped context, approval gate, tool rejection, and in-memory trace contract exist. Provider failure behavior, redaction policy, intent UX, and persistent trace semantics are missing. |
| Capability registry | Partial | A versioned JSON registry and showcase verifier exist. Per-app emission, provider bindings, feature flags, release metadata, and generation lifecycle are incomplete. |
| Compatibility policy | Partial | [compatibility_policy.md](compatibility_policy.md) and the four-lane CI scaffold exist. Required lanes have not run from this environment, and the ERB bound prevents local bundled validation. |
| Governance kickoff | Partial | A decision-log README exists. ADR template, ownership map, maintainer responsibilities, and review process are absent. |

## Gate 2: Before Beta

| Item | Status | Evidence and Remaining Gap |
| --- | --- | --- |
| API and responses | Partial | Mutation outcome/format adapter exists. Query parameter, pagination, filter, sort, HTML, JSON, and Turbo Stream contracts are not exercised in Rails requests. |
| Component contract | Partial | Filter panel, table, form, and assistant partials exist. Component APIs, loading/empty/error states, accessibility acceptance checks, and browser tests are missing. |
| Audit and compliance | Partial | Mutation and AI trace event structures exist. Required event schema, durable storage/outbox behavior, retention, redaction, access control, and export format are unspecified. |
| Showcase packaging | Partial | The showcase generator and CI manifest verifier exist. Generated showcase boot, walkthrough execution, and version-lockstep tests are absent. |
| Import/export | Missing | No specification or implementation for mapping, validation previews, field masking, background work, retry, or export authorization. |
| Testing and quality | Partial | Unit and generator-contract tests are green. No Rails integration, request, system/browser test policy, flake budget, or coverage targets exist. |
| Performance and scalability | Missing | No SLOs, UX responsiveness budgets, caching/invalidation plan, job thresholds, or measurement protocol exist. |
| Observability | Missing | No structured log schema, correlation IDs, metrics, dashboard, or tracing boundary specification exists. |
| Agent action trace | Partial | Assistant traces include actor, template, provider, fingerprint, output, references, and status. Role/context policy metadata, retention/redaction, searchable export, and mutation results are absent. |
| Conversational interface and tool routing | Partial | Fixed task routing and an allowlisted tool router exist. Controller/UI lifecycle, uncertainty signaling, provider failure behavior, and asynchronous progress semantics are absent. |
| CI matrix | Partial | Minimum, stable, latest, and allowed-to-fail preview lanes are configured. The matrix does not run browser/integration/performance checks, and local bundled validation is currently unavailable. |

## Prioritized Backlog

1. **Provider and security boundary:** Define executable authentication, authorization, tenant, and audit provider contracts; validate configuration at boot; write the security baseline and threat model.
2. **Rails integration harness:** Add a minimal host application with database, provider fixtures, request tests, and Turbo/JSON/HTML coverage for query and mutation paths.
3. **Audit durability and custom workflow API:** Add transaction-aware audit persistence or an outbox, then formalize custom actions and transitions on the mutation policy contract.
4. **Field and component authorization:** Add field-level visibility rules to list/form/show/AI contexts and component state contracts with browser accessibility tests.
5. **Showcase executable conformance:** Install and boot the showcase in CI; run its evaluator flows across roles and tenants.
6. **Operational specifications:** Define observability, performance SLOs, test pyramid/flake policy, and AI trace retention/redaction requirements.
7. **Import/export design:** Specify tenant/policy-safe import/export behavior, including preview, masking, jobs, retries, and audit events.
8. **Generator hardening:** Define collision handling, routes merging, irregular inflection, namespace behavior, and generated-app contract tests.
9. **Compatibility closure:** Resolve the Rails 8.1/ERB constraint in a reproducible bundle and run all required CI lanes.
10. **Governance:** Add ADR template, ownership, escalation, release sign-off, and security hotfix procedures.

## Material Risks

- **Critical:** Generated authentication guards and policy stubs are not connected to a validated host-provider integration, so request-level fail-closed behavior is unproven.
- **Critical:** There is no security baseline for CSRF, cookies, session lifetime, headers, or sensitive data handling.
- **High:** Audit emission follows mutation persistence without a durable transaction/outbox design; audit failure can leave a mutation completed but unrecorded.
- **High:** Query/mutation/dashboard/AI safety tests use contract doubles, not an Active Record/Rails request flow; controller and relation behavior may diverge.
- **High:** The showcase asserts capability-manifest presence but not a booted end-to-end workflow.
- **High:** Import/export, observability, performance, audit retention, and compliance contracts are absent.
- **Medium:** The compatibility range is broad, while local Bundler cannot resolve the required ERB range; current lane results are not demonstrated locally.
- **Medium:** The AI trace and context contracts need a persistent, redactable host sink before production data can be safely used.

## Exact Next Three Slices

1. **Provider Contracts and Security Baseline:** Add explicit host adapter interfaces for authentication, authorization, tenant resolution, and audit recording; add boot/config validation, contract tests, an ADR, and a CSRF/session/cookie/header threat-model document.
2. **Rails Integration Test Host:** Create a minimal Rails test app with SQLite, a tenant-aware model, role fixtures, provider adapters, and request coverage for unauthenticated, unauthorized, cross-tenant, validation, audit, HTML, JSON, and Turbo Stream paths.
3. **Custom Actions, Transitions, and Durable Audit:** Implement a first-class action/transition command API with explicit policy predicates and a transaction-aware audit/outbox contract; wire the showcase workflows to it and add end-to-end conformance tests.