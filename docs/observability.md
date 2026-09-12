# Observability Contract

KrudminAI emits structured, redacted `ActiveSupport::Notifications` events at request completion or failure, mutation completion, successful audit recording, and AI completion. Every event includes `event` and a request-scoped `correlation_id`; request controllers seed it from `request.request_id`, while non-request callers receive a generated identifier.

The event names are `krudmin_ai.request.completed`, `krudmin_ai.request.failed`, `krudmin_ai.mutation.completed`, `krudmin_ai.audit.recorded`, and `krudmin_ai.ai.completed`. Safe dimensions are event, operation, outcome, resource, and HTTP status. Hosts may configure `observability_logger`, `metrics_provider`, and `tracing_provider`; metrics providers implement `increment(name, tags:)` and tracing providers implement `record(event:, attributes:)`. Adapter failures are swallowed so telemetry cannot weaken authorization, prevent a normal error response, or interfere with transactional audit behavior.

## Redaction And Retention

Telemetry never receives request attributes or serialized records. The emitter redacts values under tenant, actor, record, field, audit, input, output, prompt, secret, password, token, cookie, session, and authorization keys before notifying, logging, counting, or tracing. Redacted values are one-way short hashes for incident correlation only. Audit and AI sinks retain data under their separate host policies; they must apply the same field allowlists and redaction rules before persistence or export.

Hosts retain application logs, metrics, traces, audit events, and AI traces according to their legal and contractual retention schedule. Access to each store is least-privilege and tenant-aware. Compliance exports must be authorized, time-bounded, redacted, encrypted in transit, and audit-recorded; raw credentials, session material, unallowlisted fields, and provider prompts/outputs are never exportable by default.

## Alerts And Recovery

Alert on sustained request failures, mutation `audit_failed` or `persistence_failed` outcomes, audit sink outages, authorization-provider failures, and AI unsafe-tool or provider-error outcomes. Alerts include only correlation IDs and safe dimensions. The incident responder uses the correlation ID to join request, mutation, audit, and AI events, follows [the incident runbook](runbooks/incident_response.md), and does not replay a mutation until audit recovery and tenant/policy checks are confirmed. Audit failure already rolls back Active Record mutations; no compensating write is permitted.