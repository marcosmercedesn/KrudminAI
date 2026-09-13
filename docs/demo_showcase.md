# Operations Showcase Demo

The companion app exposes a live facilities-operations workspace instead of a static feature page. Sign in through `/session/new`, then use the Assets, Locations, and Vendors navigation entries.

`Assets` is the primary demonstration resource. It combines sectioned forms with text, email, password, identifier, masked, currency, percentage, date, time, datetime, boolean, JSON, rich-text, file, image, enum, computed, local belongs-to, and remote belongs-to adapters. Its detail view demonstrates sensitive-value redaction and relationship display.

`Locations` supplies the tenant-scoped local lookup. `Vendors` supplies the protected remote lookup and is seeded with 26 Northwind entries, allowing the remote control's search and bounded result behavior to be exercised. Both resources also provide normal CRUD, filters, sorting, and pagination.

Each Asset has an optional deployment profile and up to six maintenance tasks. These demonstrate tenant-checked `has_one` and `has_many` nested editing. The demo schema also enables Action Text and Active Storage so rich text and upload fields run against their real Rails contracts.

All showcase resources require an authenticated demo user. Their query pipelines apply tenant scope, policy scope, declared filters, sorting, and pagination in the standard order.