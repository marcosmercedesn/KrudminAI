# Beta Readiness Checkpoint

Date: 2026-09-12

## Decision

**Hold beta.** KrudminAI `0.1.0.pre.1` is not approved for beta publication. The authoritative, machine-readable outcome and blockers are in [capability_registry.json](capability_registry.json); the accountable evidence and closure plan are in [beta_release_decision.md](beta_release_decision.md).

## Reconciled Evidence

| Area | Evidence state | Current conclusion |
| --- | --- | --- |
| Query and mutation foundations | Implemented contract | Authentication, tenant/policy scope ordering, deny-by-default authorization, normalized mutation outcomes, and transaction-aware audit hooks have engine specs. |
| Generic resources and nested editors | Companion or generated-fixture evidence | Engine templates and direct `has_many` workflows work in the demo and disposable showcase fixture; independent generated-host CRUD and association coverage is still required. |
| Providers and security | Companion evidence | Provider interfaces fail closed and generated-host guidance exists, but independent host configuration-failure evidence and release-specific session/header review remain open. |
| Responses, audit, lifecycle, fields, actions, dashboards, and AI | Contract or companion evidence | The runtime contracts exist, but every registry evidence gap must be closed in an independent host or explicitly reassigned before beta. |
| UI, navigation, and accessibility | Companion evidence | The Selenium/Chrome suite has deterministic desktop, tablet, and mobile coverage with zero automatic retries; generated-host browser proof and formal screen-reader review remain open. |
| Showcase and generators | Generated companion fixture | The disposable full showcase host migrates and executes a two-tenant scenario. It is not independent generated-host evidence for navigation, associations, or AI. |
| Compatibility | Local contract plus CI definition | Rails/Ruby bounds and four lanes are specified and tested locally. Remote passing history for blocking lanes is still required. |
| Observability and governance | Implemented contract | Correlated redacted telemetry, incident/governance documents, and readiness verifier exist; deployment hosts still own alert destinations, retention, and telemetry-store access controls. |
| Release quality | Blocked | The root CI lint command has unresolved repository-wide offenses. |

## Must-Keep Inventory

The replacement inventory's resource metadata, CRUD/search/sort/pagination, policy hooks, actions/transitions, association editors, policy-scoped dashboards, and audit extension points all have a named owning task and registry entry. Their evidence state is not upgraded beyond the proof currently available.

## Beta Exit Rule

Beta may proceed only after every item in the `beta_release_decision.blockers` list has recorded closure evidence, `ruby bin/verify_beta_decision` passes with an updated reviewed outcome, required remote CI results are linked in [release_approval.md](release_approval.md), and security and release owners approve publication. Tasks 17 through 21 remain deliberate post-beta work and are not accepted as substitutes for missing Gate 1 or Gate 2 evidence.

## Validation Record

The decision was based on the following local results:

- Engine suite: `79 examples, 0 failures`
- Compatibility spec: `3 examples, 0 failures`
- Disposable showcase host: `2 runs, 23 assertions, 0 failures`
- Companion integration: `22 runs, 306 assertions, 0 failures`
- Companion browser/accessibility: `6 runs, 193 assertions, 0 failures`
- Operational readiness and beta-decision verifiers: passed
- Root RuboCop: failing repository-wide legacy offense baseline

Use [beta_release_decision.md](beta_release_decision.md) as the next-session entry point. It assigns every beta blocker, names the required closure evidence, and prevents a decision change without an updated release approval.
