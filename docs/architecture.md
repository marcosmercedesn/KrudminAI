# Architecture

KrudminAI is an isolated Rails engine for authenticated back-office workflows. It uses Propshaft-native assets and module-based Hotwire interactions with Turbo and Stimulus. jQuery is excluded from runtime and test dependencies.

The canonical query pipeline is tenant scope, policy scope, filters, sort, pagination. Every list, search, export, dashboard, and AI context builder must use it. The implemented resource and pipeline contracts are documented in [resource_query_pipeline.md](resource_query_pipeline.md). The mutation pipeline dispatches create, update, and destroy through tenant and action authorization, normalized results, response adapters, and required audit hooks; see [mutation_pipeline.md](mutation_pipeline.md). Transitions and custom actions remain future work.

Field adapters will render deterministically for form, list, show, search, and JSON contexts. UI affordances use the same policy decisions as their endpoints. Provider failures deny access or stop the operation; they never silently broaden access.

AI context comes only from policy-authorized, tenant-scoped data with approved field allowlists. AI is suggestion-only by default. Mutations require explicit approval and a trace.