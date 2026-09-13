# Field Adapters

P1 introduces a resource-owned field adapter registry. Resources may explicitly declare an adapter with `field :title, :string`; otherwise the registry safely inspects a model's `columns_hash` and currently selects the string adapter. Unknown explicit adapters fail closed with a configuration error.

Each adapter owns its form control, list and detail presentation, JSON, CSV export, AI value, parameter, blank-value, filter, and field-policy interfaces. The string adapter retains the existing text input behavior. P2 adds the documented scalar adapters and their parsing and formatting semantics. P3 adds the sensitive, rich-text, file, image, and computed adapters documented in [sensitive_media_field_adapters.md](sensitive_media_field_adapters.md); relationship adapters remain later work.

Field read and write permissions remain resource decisions. Generic views only invoke adapters after a read decision succeeds; CSV and AI serialization follow the same policy rule. This initial implementation has engine proof only. Independently generated-host request and browser/accessibility evidence remains required before P1 can be independently proven.