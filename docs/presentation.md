# Presentation Metadata

KrudminAI resources may declare ordered form sections with `section :name, fields:, label:, columns:`. The only supported layouts are `:one` and `:two`; arbitrary CSS classes are not accepted. Fields omitted from declared sections remain visible in an automatically labelled Additional details section.

Lists may declare `list_priority :field, :primary`, `:standard`, or `:secondary`. Secondary columns are hidden below 768px while primary and standard data remains available in the semantic table. The list, form, and detail templates continue to resolve field output through resource adapters, preserving formatting and field-read policy behavior.

Host action templates remain explicit overrides. Generic layouts provide accessible fieldsets, labelled form controls, table headers, responsive table overflow, relationship blocks, and adapter-rendered association links, media, dates, currency, and identifiers.

P13 owns independent browser screenshots and accessibility proof at desktop, tablet, and mobile viewports.
