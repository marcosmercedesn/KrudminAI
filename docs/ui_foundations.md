# UI Foundations

KrudminAI ships engine-owned CSS tokens and Hotwire modules without jQuery. Load `krudmin_ai/application.css` and `krudmin_ai/index.js` through the host application's Propshaft and import-map or JavaScript bundling setup.

`krudmin-ai-theme` persists `light`, `dark`, or `system` under `krudmin-ai-theme`. It sets `data-theme` and `data-theme-mode` on the document root; system mode reacts to operating-system preference changes.

The `ui/filter_panel`, `ui/resource_table`, and `ui/form_shell` partials are initial generated-resource primitives. Their CSS uses semantic tokens, responsive grid/table constraints, visible keyboard focus, and reduced-motion fallback. The filter controller maintains `hidden` and `aria-expanded`, then focuses the first panel control when opened.

KrudminAI uses `lucide-rails` for inline SVG icons. Resources configure an icon with a Lucide identifier, using Ruby symbol notation; the default is `:file_text`. Render resource and action icons with `krudmin_ai_icon`, which normalizes underscores to Lucide's dashed icon names and marks decorative icons as hidden from assistive technology.

```ruby
class TicketsResource < KrudminAI::Resources::Base
  icon :ticket
end

krudmin_ai_icon(TicketsResource.icon, class: "resource-icon")
```

The companion demo navigation is responsive: wide screens offer a collapsible rail whose state persists in local storage under `krudmin-ai-sidebar-collapsed`; smaller screens use a closed-by-default overlay drawer. The drawer closes when the user chooses navigation, presses Escape, or selects the backdrop. Its open state is intentionally not persisted.

The companion resource screens use semantic operational states for empty results, validation errors, notices, alerts, loading (`aria-busy`), and disabled controls. Empty results retain a clear create action, validation errors are announced with a summary and invalid field state, and ticket state badges retain their written state label so that meaning does not rely on color. Resource tables scroll inside their own wrapper on narrow screens rather than expanding the document width.

## Visual Regression Evidence

Run the deterministic companion browser suite with:

```sh
cd demo
bundle exec ruby -Itest test/system/admin_visual_regression_test.rb
```

The suite recreates tenant-scoped fixtures, signs in through the demo session screen, and saves PNG evidence under `demo/tmp/visual_regression`. It captures the ticket list, new form, edit form, show page, and dashboard in light and dark modes; the ticket list at tablet width in both modes; and expanded/collapsed desktop rail plus closed/open mobile-drawer states. Before each capture it fails if the primary heading or Lucide icon set is missing, or if the document has horizontal overflow. Generated PNGs are local test artifacts, not source-controlled approved snapshots: rerun the suite after intentional UI changes and inspect the regenerated files before accepting the change.

## Engine Admin Shell

`KrudminAI::ResourceController` uses the engine-owned `krudmin_ai/application` layout by default. The layout loads the engine stylesheet and renders only navigation items registered by the host. A host that needs a bespoke presentation can retain the resource controller and declare its own Rails `layout` in the host controller.

Register navigation through `KrudminAI.configure`. Each item has a host route helper or route callable, an optional label and icon, an optional resource, a visibility predicate, and an optional active-state predicate. Resource-backed items use the resource's plural model label and its `icon`; all other items fall back to `:file_text`. The visibility predicate receives the same `AccessContext` constructed for the request, so the host can apply the same policy decision to the affordance and endpoint.

```ruby
KrudminAI.configure do |config|
  config.navigation_item(
    resource: OrdersResource,
    route: :orders_path,
    visible: ->(context) { OrderPolicy.new(context.actor, Order).index? }
  )
  config.navigation_item(
    label: "Reports",
    route: ->(view) { view.main_app.reports_path },
    icon: :chart_no_axes_combined,
    visible: ->(context) { context.roles.include?(:manager) }
  )
end
```

```haml
= render "krudmin_ai/ui/filter_panel", url: orders_path do |form|
  .krudmin-ai-field
    = form.label :status
    = form.select :status, Order.statuses.keys
```