# Dashboards

KrudminAI widgets receive a resource, authenticated `AccessContext`, and a base relation. Widgets never accept precomputed aggregate values. They derive their data through the resource's tenant and policy scopes, preventing cross-tenant and unauthorized aggregate leakage.

```ruby
context = KrudminAI::AccessContext.new(actor: current_user, tenant: current_tenant, roles: current_user.roles)

count = KrudminAI::Dashboards::Widgets::Count.new(resource: OrdersResource, context:, relation: Order.all)
table = KrudminAI::Dashboards::Widgets::Table.new(resource: OrdersResource, context:, relation: Order.all, columns: %i[number status], limit: 10)
summary = KrudminAI::Dashboards::Widgets::Summary.new(
  resource: OrdersResource,
  context:,
  relation: Order.all,
  summarize: ->(relation) { { total: relation.sum(:amount) } }
)
```

`Count` and `Summary` use the authorized relation after tenant scope, policy scope, and whitelisted filters. `Table` uses the full query pipeline, including default or requested whitelisted sort and bounded pagination.

## Custom Widgets

Subclass `KrudminAI::Dashboards::Widgets::Base` and derive data only through `authorized_relation` or `paginated_relation`. Do not retain an unscoped relation, accept aggregate input from callers, or call model-level queries directly. Add a contract test proving records from another tenant and records denied by policy cannot affect the output.