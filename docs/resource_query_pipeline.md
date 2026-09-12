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
end

context = KrudminAI::AccessContext.new(actor: current_user, tenant: current_organization, roles: current_user.roles)
result = KrudminAI::QueryAccessPipeline.new(resource: OrdersResource, context:, params: request.query_parameters).call(Order.all)
```

The pipeline always applies tenant scope, policy scope, whitelisted filters, whitelisted sort, then pagination. Unknown filters, malformed sort values, invalid page numbers, and oversized page requests cannot alter the relation outside those rules.