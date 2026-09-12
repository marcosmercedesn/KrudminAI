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

## Dashboard Lifecycle

Subclass `KrudminAI::Dashboards::Base` to register host-configurable widgets. Every widget supplies a resource, a relation factory, and an explicit `visible` predicate. Visibility denies by default: a missing, false, or exception-producing predicate omits the widget entirely. The resource pipeline still scopes every visible widget's data.

```ruby
class OperationsDashboard < KrudminAI::Dashboards::Base
  label "Operations"

  widget :open_queue,
    widget_class: KrudminAI::Dashboards::Widgets::Count,
    resource: TicketsResource,
    relation: ->(_context) { Ticket.all },
    visible: ->(context) { context.roles.include?(:support_agent) },
    query_params: { filters: { state: "open" } },
    drill_down_filters: { state: "open" }
end
```

`Dashboard#render` returns normalized widget results with `ready`, `empty`, `error`, or explicit `loading` state. Policy and scope denials hide the affected widget. Unexpected errors return an error state without exposing the exception. A host refresh action can render the same results as a Turbo Stream replacement.

Table widget rows are serialized only through each resource's field read policies. Read-denied columns and values are absent. Drill-down filters are limited to the target resource's declared filters; the target resource URL must continue through `ResourceController`, which reapplies tenant, policy, archive, sort, and pagination rules.

## Custom Widgets

Subclass `KrudminAI::Dashboards::Widgets::Base` and derive data only through `authorized_relation` or `paginated_relation`. Do not retain an unscoped relation, accept aggregate input from callers, or call model-level queries directly. Add a contract test proving records from another tenant and records denied by policy cannot affect the output.