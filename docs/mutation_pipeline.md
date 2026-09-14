# Mutation Pipeline

`KrudminAI::MutationPipeline` accepts `create`, `update`, `destroy`, archive lifecycle operations, and resource-declared custom actions/transitions. Each command validates the authenticated actor and tenant, checks record tenancy, evaluates the explicit action policy, checks field write policies for action-declared writes, persists the record, and emits an audit event. For Active Record records, persistence and audit recording share one database transaction: an audit exception rolls back the mutation. Missing authorization, tenant ownership, field permission, or audit configuration stops the command before persistence. See [resource_actions.md](resource_actions.md) for action and transition declarations.

```ruby
class OrdersResource < KrudminAI::Resources::Base
  model Order
  tenant_record { |record, context| record.organization == context.tenant }
  authorize(:create) { |_record, context| context.roles.include?(:manager) }
  authorize(:update) { |record, context| OrderPolicy.new(context.actor, record).update? }
  authorize(:destroy) { |record, context| OrderPolicy.new(context.actor, record).destroy? }
end

result = KrudminAI::MutationPipeline.new(resource: OrdersResource, context:, auditor: audit_sink)
  .call(operation: :update, record: order, attributes: permitted_attributes)
response = KrudminAI::MutationResponseAdapter.for(result, format: request.format.symbol)
```

For declared direct `has_many` relationships, the pipeline validates every existing child ID through the parent association and evaluates the relationship's child tenant and action predicates before assigning nested attributes. New child rows receive the parent tenant before validation. Active Record saves parent and children atomically; invalid children retain nested errors on the parent form. Audit events include affected child IDs. See [nested_relationships.md](nested_relationships.md).

The pipeline is the authoritative validation boundary. Client-side validation projects a narrower subset of the same rules into the browser to report problems earlier, and never changes what the pipeline accepts or rejects. See [client_side_validation.md](client_side_validation.md).

## Response Contract

`KrudminAI::MutationResponseAdapter` renders `html`, `json`, and `turbo_stream`, and rejects any other format rather than guessing one.

| Outcome | HTML | JSON | Turbo Stream |
| --- | --- | --- | --- |
| success | 303 redirect | 200, or 201 for create | 200 with the operation's success stream |
| invalid | 422 re-render | 422 | 422 with the operation's error stream |
| unauthenticated | 401 | 401 | 401 |
| tenant_required, forbidden | 403 | 403 | 403 |
| configuration_error, audit_failed, persistence_failed | 500 | 500 | 500 |

Every successful non-GET HTML mutation answers 303, including bulk actions, because Turbo repeats the request on a 302.

A Turbo browser advertises `text/vnd.turbo-stream.html` on every form submission, so the stream format alone cannot mean "update in place". Streaming is therefore opt-in: a submission originating inside an engine inline frame, whose id starts with `krudmin-ai-inline-`, receives the stream, and every other successful mutation redirects with 303 so Turbo navigates. The prefix is deliberately engine-owned, so a host frame wrapping engine content never silently turns a full-page form into an in-place update. The engine's inline editor is the one built-in form inside such a frame, which keeps the list in place while a full-page form still lands on the record.

A successful stream response carries a `Turbo-Location` header pointing at the collection for `destroy` and `archive` and at the record for every other operation. Failures always stream when the client asked for a stream, so a rejected form re-renders in place with 422 and carries no location.

Mutation streams update the contents of `#krudmin-ai-flash` rather than replacing the element, so the target survives and a host layout keeps its own flash container. A host that renders engine resources under its own layout must provide that element for stream feedback to appear.

The reasoning and rejected alternatives are recorded in [decisions/0001-turbo-mutation-response-contract.md](decisions/0001-turbo-mutation-response-contract.md).

Bulk actions answer all three formats under the same rule, and a rejected or unauthorized bulk action reports through the requested format rather than always answering JSON.


The normalized result uses `success`, `unauthenticated`, `tenant_required`, `forbidden`, `invalid`, `configuration_error`, `audit_failed`, and `persistence_failed` outcomes. `ResourceController` sends every mutation through `MutationResponseAdapter`: HTML success returns a `303` redirect; JSON returns `{ data, errors, outcome }` with `201` for creates and mapped error statuses; Turbo Stream renders an operation-specific success or error stream and uses `Turbo-Location` after success.

## Audit Recovery And Retention

An audit provider failure aborts the transaction and returns the `audit_failed` outcome with no durable record mutation or effective audit event. Retrying the request after the provider recovers performs one normal mutation and emits one event. Providers must treat `AuditEvent` as immutable, persist actor, tenant, roles, operation, record identifier, and affected child references, and retain events under the host's compliance policy. Audit readers must be separately authorized and metadata must be redacted before persistence; do not store secrets, session identifiers, credentials, raw export data, or unallowlisted AI content.