# Resource Query Pipeline

Every generated admin resource will require authentication. A request must create an `AccessContext` with an actor, tenant, and normalized roles; absent actor or tenant values raise before a relation is queried.

Resources declare a model, tenant scope, policy scope, allowed filters, allowed sort fields, a default sort, and pagination limits. Missing tenant or policy scope is a configuration error. A policy scope that returns `nil` or `false` denies access.

```ruby
class OrdersResource < KrudminAI::Resources::Base
  model Order
  tenant_scope { |relation, context| relation.where(organization: context.tenant) }
  policy_scope { |relation, context| OrderPolicy::Scope.new(context.actor, relation).resolve }
  filter(:status) { |relation, value, _context| relation.where(status: value) }
  sortable :created_at, :status
  default_sort_by :created_at, direction: :desc
  paginate per_page: 25, max_per_page: 100
  includes :customer
  preload :line_items
  archive :archived_at
end

context = KrudminAI::AccessContext.new(actor: current_user, tenant: current_organization, roles: current_user.roles)
result = KrudminAI::QueryAccessPipeline.new(resource: OrdersResource, context:, params: request.query_parameters).call(Order.all)
```

The pipeline always applies tenant scope, policy scope, provider scope, archive visibility, eager-load directives, whitelisted filters, whitelisted sort, then pagination. Unknown filters, malformed sort values, invalid page numbers, oversized page requests, and invalid archive values cannot alter the relation outside those rules.

## Eager Loading

Use `includes` for associations used in conditions or rendering that may require joins, and `preload` for associations rendered separately. The pipeline applies these declarations only after tenant and policy scopes have narrowed the relation. Relationship views should have a query-count regression test; the companion ticket editor verifies that multiple passenger rows load with one passenger query.

## Archive Lifecycle

`archive :archived_at` makes the default query return records whose archive column is `NULL`. The public `archive` parameter accepts only `active` (default), `archived`, or `all`; any other value safely falls back to `active`. A configured resource turns its conventional `DELETE` into an audited `archive` mutation. Hosts add a member `PATCH :restore` route and declare explicit `authorize(:archive)` and `authorize(:restore)` predicates. Restore loads only an authorized archived record; active records remain unavailable through that endpoint. Resources without `archive` retain conventional hard deletion.