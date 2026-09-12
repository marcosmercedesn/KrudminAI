# UI Foundations

KrudminAI ships engine-owned CSS tokens and Hotwire modules without jQuery. Load `krudmin_ai/application.css` and `krudmin_ai/index.js` through the host application's Propshaft and import-map or JavaScript bundling setup.

`krudmin-ai-theme` persists `light`, `dark`, or `system` under `krudmin-ai-theme`. It sets `data-theme` and `data-theme-mode` on the document root; system mode reacts to operating-system preference changes.

The `ui/filter_panel`, `ui/resource_table`, and `ui/form_shell` partials are initial generated-resource primitives. Their CSS uses semantic tokens, responsive grid/table constraints, visible keyboard focus, and reduced-motion fallback. The filter controller maintains `hidden` and `aria-expanded`, then focuses the first panel control when opened.

```haml
= render "krudmin_ai/ui/filter_panel", url: orders_path do |form|
  .krudmin-ai-field
    = form.label :status
    = form.select :status, Order.statuses.keys
```