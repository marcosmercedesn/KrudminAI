# 1.0 Release Gate

KrudminAI cannot publish `1.0.0` until the beta decision is no longer `hold` and the release approval record is complete. The 1.0 owner and security reviewer must confirm all supported Rails/Ruby lanes, generated-host behavior, browser/accessibility evidence, provider/audit durability, and migration evidence before tagging a release.

The migration gate requires a representative legacy Car/Passenger host migration using [migration.md](migration.md), completed without compatibility shims for unsupported functionality. The host must pass the migration checklist, demonstrate tenant and policy isolation, retain nested validation errors, reject forged child IDs, and emit audit records. Any legacy feature excluded from 1.0 needs an explicit replacement plan, owner, removal timeline, and migration note.

Public APIs follow the compatibility policy: semantic versioning, actionable warnings for deprecations, at least one minor release before removal, and release notes for security exceptions. Every 1.0 candidate requires a reviewed rollback version and owner, blocking CI results, operational readiness verification, and a completed [release approval](release_approval.md).

This gate is intentionally unsatisfied for `0.1.0.pre.1`; it records the evidence required for 1.0 and does not override the beta hold.