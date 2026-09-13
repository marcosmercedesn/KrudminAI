# Member Administration Implementation Tasks

Complete these tasks in order. Each task is intentionally small enough for an agent to implement and verify without widening the security boundary. Record completed work and host-specific decisions in a host-owned tracking file; do not edit this generated template.

## Phase 0: Foundation

- [ ] **Create the Rails host and install KrudminAI.** Add the gem, run `bin/rails generate krudmin_ai:install`, commit the generated initializer/import map/docs, and run `bin/rails generate krudmin_ai:docs_sync` a second time to prove idempotency.
- [ ] **Implement local authentication.** Create a seeded development administrator and an authenticated session flow. Prove anonymous access to every admin route is denied.
- [ ] **Define the tenant boundary.** Choose the tenant model and actor membership model. Implement the tenant provider from verified actor state; prove that a browser parameter cannot switch tenants.
- [ ] **Implement authorization and audit providers.** Use named provider objects, not lambdas. Add tests for allowed, denied, nil, malformed, and raised provider results. Ensure audit persistence failure rolls back a mutation.
- [ ] **Set production security defaults.** Keep CSRF protection, secure session cookies, parameter filtering, HTTPS/HSTS, CSP, clickjacking protection, and session timeout. Document operational owners for retention and incident response.

## Phase 1: Members

- [ ] **Model members and policy.** Add tenant-owned members with stable raw identifiers, lifecycle state, and only the profile fields with an approved purpose. Add database constraints and a deny-by-default policy.
- [ ] **Generate `MembersResource`.** Run `bin/rails generate krudmin_ai:resource Member`, then declare tenant scope, policy scope, tenant record check, fields, field decisions, routes, and audit-aware create/update/destroy permissions.
- [ ] **Build member discovery.** Add only necessary list columns, typed allowlisted filters, explicitly sortable fields, bounded pagination, and protected export behavior. Prove tenant and policy separation for list, filter, sort, pagination, and export.
- [ ] **Build member profile editing.** Use logical sections, accessible controls, and field-level write policy. Prove an unchanged form saves, invalid input preserves data, denied fields cannot be submitted, and cross-tenant IDs fail.
- [ ] **Add lifecycle operations.** Implement activation, suspension, archival, or similar operations as declared actions/transitions with confirmation, explicit authorization, reason capture where required, and audit assertions.

## Phase 2: Teams And Memberships

- [ ] **Model teams and memberships.** Put the tenant key on both models and join records. Add unique and date-range constraints that prevent duplicate active assignments.
- [ ] **Generate `TeamsResource` and relationship fields.** Use a protected local or remote lookup based on expected size. Prove label read rules and forged target IDs are denied.
- [ ] **Choose the membership editing boundary.** Use bounded nested `has_many` fields for a handful of assignments, or a dedicated `MembershipsResource` for larger/history-sensitive work. Do not implement both without a documented reason.
- [ ] **Add role and assignment policies.** Prevent privilege escalation by ensuring a manager cannot grant a role they do not control. Test server enforcement and matching UI visibility.
- [ ] **Audit relationship changes.** Confirm create, update, end-date, and reassignment events identify actor, tenant, subject, before/after safe metadata, and request trace.

## Phase 3: Notes And Attachments

- [ ] **Classify notes.** Decide which notes are operational, restricted, or prohibited. Add field read/write/reveal decisions and Rails parameter filtering before adding rich text.
- [ ] **Enable rich text deliberately.** Configure Action Text, limit the resource fields, and test policy denial plus permitted render/edit behavior.
- [ ] **Define attachment policy.** Document accepted file classes, size limits, malware scanning, storage location, delivery authorization, retention, and deletion ownership.
- [ ] **Enable Active Storage attachments.** Add attachment models/fields only after the policy is accepted. Test unauthorized download denial, tenant isolation, and audit metadata without file contents.

## Phase 4: Reporting, Import, And AI

- [ ] **Add dashboards only for approved metrics.** Every widget uses the protected relation and an explicit visibility predicate. Prove drill-downs retain tenant/policy filters.
- [ ] **Design imports before implementing them.** Define file schema, dry-run output, row error handling, idempotency key, reviewer approval, and audit model. Test bad rows and cross-tenant references.
- [ ] **Add read-only AI assistance.** Start with one task, a field allowlist, a redacting trace store, provider-failure behavior, and request/system tests that prove it cannot widen the relation or write data.
- [ ] **Require review for AI proposals.** Do not enable mutation-capable automation until the proposal, evidence, reviewer, approval policy, canonical lookup, mutation-pipeline, and audit-trace requirements are independently tested.

## Release Gate

- [ ] Verify anonymous denial, tenant separation, policy denial, CSRF behavior, field read/write denial, ID forgery rejection, attachment protection, audit rollback, and AI context redaction.
- [ ] Run the host unit, request, and system suites; manually inspect the principal member, membership, and attachment workflows using non-production data.
- [ ] Parse `docs/krudmin_ai/capability_registry.json`, update host-owned documentation, and have security/product owners approve the access matrix and retention decisions.
- [ ] Do not declare the replacement ready based on visual similarity alone. Require evidence for the roles, workflows, data migration/reconciliation, rollback, and operational support model actually selected by the host.