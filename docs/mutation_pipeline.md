# Mutation Pipeline

`KrudminAI::MutationPipeline` accepts only `create`, `update`, and `destroy`. Each command validates the authenticated actor and tenant, checks record tenancy, evaluates the explicit action policy, persists the record, and emits an audit event. Missing authorization, tenant ownership, or audit configuration stops the command before persistence.

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

The normalized result uses `success`, `unauthenticated`, `tenant_required`, `forbidden`, `invalid`, `configuration_error`, `audit_failed`, and `persistence_failed` outcomes. HTML success returns a `303` redirect, JSON create returns `201`, and Turbo Stream selects an operation-specific success or error template. Controller integration and transaction-aware audit persistence are deferred to a later Rails integration slice.