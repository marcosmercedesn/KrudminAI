# Incident Response Runbook

1. Acknowledge the alert and assign an incident commander and communications owner.
2. Capture the correlation ID, safe event dimensions, release version, affected tenant count, and first-seen time. Do not paste redacted source values, credentials, prompts, or session data into tickets or chat.
3. Contain the impact: disable the affected provider, feature, or workflow; preserve tenant and policy enforcement; do not bypass audit requirements.
4. Classify cross-tenant disclosure, authentication bypass, missing audit events, and unapproved mutation as security incidents. Escalate according to the host's legal, privacy, and customer-notification obligations.
5. Recover using a tested rollback or forward fix. Audit failures require verifying that the original mutation rolled back before any retry.
6. Close only after alert recovery, tenant-scoped data verification, audit/AI trace review, and a recorded follow-up. Create an ADR when the remedy changes architecture or policy.