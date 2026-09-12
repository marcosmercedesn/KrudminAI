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

The normalized result uses `success`, `unauthenticated`, `tenant_required`, `forbidden`, `invalid`, `configuration_error`, `audit_failed`, and `persistence_failed` outcomes. `ResourceController` sends every mutation through `MutationResponseAdapter`: HTML success returns a `303` redirect; JSON returns `{ data, errors, outcome }` with `201` for creates and mapped error statuses; Turbo Stream renders an operation-specific success or error stream and uses `Turbo-Location` after success.

## Audit Recovery And Retention

An audit provider failure aborts the transaction and returns the `audit_failed` outcome with no durable record mutation or effective audit event. Retrying the request after the provider recovers performs one normal mutation and emits one event. Providers must treat `AuditEvent` as immutable, persist actor, tenant, roles, operation, record identifier, and affected child references, and retain events under the host's compliance policy. Audit readers must be separately authorized and metadata must be redacted before persistence; do not store secrets, session identifiers, credentials, raw export data, or unallowlisted AI content.