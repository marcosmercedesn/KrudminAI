# Beta Release Decision

Date: 2026-09-12

## Outcome

**Hold beta.** `0.1.0.pre.1` is not approved for beta publication. The decision owner is the KrudminAI maintainers. The earliest target is `0.1.0.beta.1` only after every beta exit criterion below passes and the release approval record is completed.

## Local Evidence

| Evidence | Result | Classification |
| --- | --- | --- |
| Engine suite | `79 examples, 0 failures` | Engine contract |
| Compatibility contract | `3 examples, 0 failures` | Engine contract |
| Disposable showcase host | `2 runs, 23 assertions, 0 failures` | Generated companion fixture |
| Demo integration | `22 runs, 306 assertions, 0 failures` | Companion evidence |
| Demo browser/accessibility | `6 runs, 193 assertions, 0 failures` | Companion evidence |
| Operational readiness verifier | Passes | Repository artifact |
| Root lint command | Fails with repository-wide legacy offenses | Release blocker |

The CI workflow defines minimum, stable, latest, and non-blocking preview lanes, but no remote execution history was available during this decision. A workflow definition is not a passing compatibility record.

## Assigned Beta Exit Criteria

| Blocker | Owner | Target | Required closure evidence |
| --- | --- | --- | --- |
| Root lint baseline is failing | Maintainers | Quality gate | `bundle exec ruby -S rubocop` passes in a clean CI environment. |
| Generated generic CRUD proof is fixture-only | Engine maintainers | Tasks 1 and 9 | Independently created Rails host proves anonymous denial, tenant scope, CRUD, audit, and list-to-edit browser flow. |
| Relationship coverage is only companion `has_many` | Engine maintainers | Task 2 | Generated host proves validation, add/remove, cross-tenant rejection, and supported `has_one`/nested `belongs_to` boundaries. |
| Provider and security baseline lacks generated-host failure evidence | Security owner | Task 3 | Provider conformance and boot-time failure tests run in an independent host; session, header, and parameter-filter policy is reviewed. |
| Mutation responses and durable audit lack full host evidence | Engine and security owners | Task 4 | HTML, JSON, and Turbo mutation outcomes plus audit rollback/recovery run in an independent host. |
| Lifecycle, fields, actions, dashboards, and AI remain incomplete or companion-only | Domain maintainers | Tasks 5 through 8 and 18 | Each registry evidence gap has matching generated-host or explicitly approved deferral evidence. |
| Generated-host UI/browser and remote matrix history are absent | Release owner | Tasks 12 through 14 | Required viewports/themes/accessibility checks and all blocking CI lanes have successful recorded runs. |
| Production alert routing, telemetry retention, and store access controls are host-owned | Operations owner | Task 15 deployment review | A release-specific host approval records alert destinations, retention, access control, and incident contacts. |

## Deferrals And Risk

Tasks 17 through 21 are deliberate post-beta work. They do not invalidate this hold decision because beta publication is already blocked by the assigned Gate 1/Gate 2 evidence above; they cannot be treated as accepted substitutes for missing beta evidence. No beta-blocking item is accepted as a release deferral.

The accepted pre-beta limitation is that local results establish only engine-contract, companion, or generated-companion-fixture evidence. They do not establish independent host compatibility or remote CI history. The release owner must rerun this reconciliation after each blocker closes and change the registry outcome only through a reviewed release approval.