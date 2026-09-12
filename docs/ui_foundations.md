# UI Foundations

KrudminAI ships engine-owned CSS tokens and Hotwire modules without jQuery. The install generator adds a managed `KRUDMIN_AI_IMPORTMAP` block with the `krudmin_ai` entrypoint and every engine controller pin. Hosts using a bundler can load `krudmin_ai/application.css` and `krudmin_ai/index.js` through their normal asset setup instead.

The generic form renders each declared direct `has_many` relationship through an accessible nested editor. Its `krudmin-ai-nested-fields` controller adds rows from an HTML template and marks persisted rows for Rails nested-attribute deletion. The server enforces the row limit and child access checks; client controls are only a convenience. See [nested_relationships.md](nested_relationships.md).

Generic show pages render each declared relationship as a responsive table using its `display:` fields (or its editable fields by default). Every related value is individually filtered through the relationship field-read policy.

`krudmin-ai-theme` persists `light`, `dark`, or `system` under `krudmin-ai-theme`. It sets `data-theme` and `data-theme-mode` on the document root; system mode reacts to operating-system preference changes.

## Component Contract

Engine-owned resource pages compose partial components instead of requiring host resource templates. A host can override a resource action template conventionally, but generated defaults use these stable component inputs:

| Component | Required locals | Contract |
| --- | --- | --- |
| `ui/status` | `state`, `message` | `error` announces with `role="alert"`; other states announce with `role="status"`. |
| `ui/empty_state` | `title` | Optional `id` and `action`; retains an authorized creation affordance when available. |
| `ui/field` | `form`, `field`, `writable`, `access_note_id`, `errors` | Transitional generic scalar control that renders labels, invalid state, disabled/explained authorization denial, and field errors. It is not a type-specific field adapter. |
| `ui/filter_form` | implicit resource-controller context | Renders only declared filters and preserves normal GET query behavior. |
| `ui/list_table` | `resource`, `records`, `fields` | Renders only field-readable values; `state` values have visible text badges. |
| `ui/pagination` | `page`, `per_page`, `records_count` | Uses `pagination_path`, which carries only the resource controller's allowlisted query parameters. |
| `ui/record_details` | `resource`, `record`, `fields` | Renders only readable show fields and represents blank values as text. |

The `ui/filter_panel`, `ui/resource_table`, and `ui/form_shell` partials remain available for host-composed interfaces. Engine-owned default index, form, and show templates consume a resource's `list`, `form`, and `show` metadata and normal Rails controls for permitted scalar fields. This is not yet type-aware: the generic form currently renders a text control and details render raw values. The field adapter foundation must replace that behavior before KrudminAI can claim field parity. Their CSS uses semantic tokens, responsive grid/table constraints, visible keyboard focus, disabled control treatment, and reduced-motion fallback. The filter controller maintains `hidden` and `aria-expanded`, then focuses the first panel control when opened.

KrudminAI uses `lucide-rails` for inline SVG icons. Resources configure an icon with a Lucide identifier, using Ruby symbol notation; the default is `:file_text`. Render resource and action icons with `krudmin_ai_icon`, which normalizes underscores to Lucide's dashed icon names and marks decorative icons as hidden from assistive technology.

```ruby
class TicketsResource < KrudminAI::Resources::Base
  icon :ticket
end

krudmin_ai_icon(TicketsResource.icon, class: "resource-icon")
```

The engine `krudmin-ai-navigation` controller provides responsive navigation: wide screens offer a collapsible rail whose state persists in local storage under `krudmin-ai-sidebar-collapsed`; screens at or below `70rem` use a closed-by-default overlay drawer. The drawer closes when the user chooses navigation, presses Escape, or selects the backdrop. Its open state is intentionally not persisted. The icon-only toggle always has an `aria-label`, an `aria-controls` relation, and an `aria-expanded` value synchronized with the visible navigation state.

The companion resource screens use semantic operational states for empty results, validation errors, success notices, errors, loading (`aria-busy`), and disabled controls. Empty results retain a clear create action, validation errors are announced with a summary and invalid field state, and ticket state badges retain their written state label so that meaning does not rely on color. Resource tables scroll inside their own wrapper on narrow screens rather than expanding the document width. Pagination controls preserve declared filters and use explicit current-page text; a next-page control appears only when the current bounded result page is full.

## Tokens And Themes

`krudmin_ai/application.css` publishes semantic canvas, surface, raised-surface, text, muted-text, border, accent, edit, success, focus, danger, radius, spacing, shadow, and transition tokens. Light values are the default; `data-theme="dark"` supplies dark values; system mode uses `prefers-color-scheme` unless `data-theme-mode` is explicitly light or dark. Components use these semantic tokens rather than literal component-specific colors.

Buttons use a semantic action contract: the neutral default is for cancellation, filtering, pagination, and non-mutating controls; `--primary` is for creating a resource; `--edit` is for editing; `--save` is for persisting form changes; and `--danger` is for destructive actions. Color supports the written label and never carries the action meaning by itself.

Engine-owned default actions pair their labels with decorative Lucide icons: plus for create/add, pencil for edit, save for persistence, x for cancel, filter controls for filtering, directional arrows for pagination, and trash for deletion. Icon-only destructive controls retain an accessible name through their `aria-label` and `title`.

## Visual Regression Evidence

Run the deterministic companion browser suite with:

```sh
cd demo
bundle exec ruby -Itest test/system/admin_visual_regression_test.rb
```

The suite recreates tenant-scoped fixtures, signs in through the demo session screen, and saves PNG evidence under `demo/tmp/visual_regression`. It captures the ticket list, new form, edit form, show page, and dashboard in light and dark modes; the ticket list at tablet width in both modes; and expanded/collapsed desktop rail plus closed/open mobile-drawer states. Before each capture it fails if the primary heading or Lucide icon set is missing, or if the document has horizontal overflow. Generated PNGs are local test artifacts, not source-controlled approved snapshots: rerun the suite after intentional UI changes and inspect the regenerated files before accepting the change.

The driver, CI flake budget, screenshot artifact process, and accessibility coverage are specified in [browser_testing.md](browser_testing.md). The browser suite is companion evidence and does not replace the independent generated-host browser matrix required for beta claims.

The current release decision remains [hold](beta_release_decision.md) until that generated-host browser evidence and the other assigned beta exit criteria close.

## Engine Admin Shell

`KrudminAI::ResourceController` uses the engine-owned `krudmin_ai/application` layout by default. The layout loads engine CSS and the `krudmin_ai` import-map entrypoint, renders only navigation items registered by the host, and provides a persistent desktop rail, a mobile drawer, and the light/dark/system selector. A host that needs a bespoke presentation can retain the resource controller and declare its own Rails `layout` in the host controller.

Register navigation through `KrudminAI.configure`. Each item has a host route helper or route callable, an optional label and icon, an optional resource, a visibility predicate, and an optional active-state predicate. Resource-backed items use the resource's plural model label and its `icon`; all other items fall back to `:file_text`. The visibility predicate receives the same `AccessContext` constructed for the request, so the host can apply the same policy decision to the affordance and endpoint. Visibility and custom active predicates must return exactly `true`; nil, other values, and exceptions fail closed (hidden or inactive).

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