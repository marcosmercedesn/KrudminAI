# Actions, Workflows, and Bulk Operations

A resource action is explicit. Its declaration includes an action handler, the fields it writes, label, Lucide icon, placement (`:record`, `:list`, or `:both`), HTTP method (`:post`, `:patch`, or `:delete`), optional confirmation text, and semantic variant (`:default`, `:primary`, `:edit`, or `:danger`). Generic action controls render only when the normal per-record action authorization allows them.

State transitions are declared actions. A transition accepts only its stated source values and records a validation error for an invalid transition.

Bulk execution requires `bulk_action :action_name` after the corresponding action declaration. The endpoint resolves every submitted ID through the canonical protected relation, rejects the whole request if any requested ID is missing or outside that relation, performs per-record action and written-field authorization before mutation, then runs every approved target through `MutationPipeline` and its transactional audit contract.

Inline editing is opt-in through `inline_edit`. It permits only String/Text, Number/Decimal/Currency/Percentage, Boolean, Date/DateTime, Enum, and protected BelongsTo adapters. The list control submits a normal single-field PATCH and therefore receives the same tenant, policy, adapter validation, transaction, and audit protection as the full form.

P13 owns independent browser and accessibility proof for confirmations, keyboard operation, prohibited controls, Turbo responses, and bulk selection interaction.
