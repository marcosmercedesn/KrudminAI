# Dashboard Widgets

Use `KrudminAI::Dashboards::Base` to declare a dashboard widget. A widget always needs a resource, a relation factory, and an explicit `visible:` predicate. The relation is secured by the engine query pipeline; do not calculate widget values in a controller or template.

## Icons

Set `icon:` to a Lucide icon identifier using Ruby symbol notation. The dashboard result exposes the normalized identifier as `widget.icon`.

```ruby
class OperationsDashboard < KrudminAI::Dashboards::Base
  widget :open_orders,
    widget_class: KrudminAI::Dashboards::Widgets::Count,
    resource: OrdersResource,
    relation: ->(_context) { Order.all },
    visible: ->(context) { context.roles.include?(:operations) },
    label: "Open orders",
    icon: :package_open,
    color: :amber,
    query_params: { filters: { state: "open" } },
    drill_down_filters: { state: "open" }
end
```

Render the icon through the engine helper and retain the resource icon as the fallback:

```erb
<%= krudmin_ai_icon(widget.icon || widget.resource.icon) %>
```

Do not render an icon name supplied by a request parameter. Dashboard definitions are application code, and the configured symbol is safe metadata.

## Colors

Set `color:` to `:blue`, `:teal`, `:green`, `:amber`, `:orange`, or `:red`. The default is `:blue`; unsupported values raise an application-boot configuration error. The result exposes the selected value as `widget.color`. Apply it through an allowlisted semantic class in the host dashboard template:

```erb
<span class="metric-icon metric-icon--<%= widget.color %>">
  <%= krudmin_ai_icon(widget.icon || widget.resource.icon) %>
</span>
```

The host owns the CSS implementations of its semantic color classes. Pair each color with a subtle tinted card surface, matching border, and stronger accent edge so the numeric value remains readable. Do not interpolate arbitrary color values, request parameters, or user-supplied CSS into a dashboard template.

## Required Controls

- `visible:` must return exactly `true` for the current `AccessContext`; absent, false, malformed, or exception-producing decisions hide the widget.
- `query_params:` and `drill_down_filters:` may use only filters declared by the target resource.
- Table widget values must continue through field read policy. Do not use raw model values in templates.
- Add focused coverage for visibility, tenant/policy scope, filters, and the selected icon when a widget is added or changed.