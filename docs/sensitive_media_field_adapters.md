# Sensitive And Media Field Adapters

P3 provides `:masked`, `:rich_text`, `:file`, `:image`, and `:computed` field adapters. QR-code fields are out of scope.

Masked values render as `[REDACTED]` and are omitted from JSON, CSV, and AI context. A raw value can be obtained only through `KrudminAI::Fields::Reveal`, which requires both normal field-read authorization and a separate `reveal:` field policy. Every successful reveal records metadata only; it never records the value.

Rich-text fields require the host model to declare `has_rich_text :field_name`. File and image fields require an Active Storage `has_one_attached` or `has_many_attached` declaration. Missing declarations raise a configuration error rather than silently degrading. Generic details render attached images and file links. Computed fields require a `value:` callable and reject submitted values.

P13 owns the independent browser/accessibility evidence for these fields after the complete presentation surface exists.