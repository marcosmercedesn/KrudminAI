# Architecture

KrudminAI is an isolated Rails engine for authenticated back-office workflows. It uses Propshaft-native assets and module-based Hotwire interactions with Turbo and Stimulus. jQuery is excluded from runtime and test dependencies.

The canonical query pipeline is tenant scope, policy scope, filters, sort, pagination. Every list, search, export, dashboard, and AI context builder must use it. The future mutation pipeline dispatches create, update, destroy, transition, and custom-action commands through explicit authorization, normalized results, response adapters, and audit hooks.

Field adapters will render deterministically for form, list, show, search, and JSON contexts. UI affordances use the same policy decisions as their endpoints. Provider failures deny access or stop the operation; they never silently broaden access.

AI context comes only from policy-authorized, tenant-scoped data with approved field allowlists. AI is suggestion-only by default. Mutations require explicit approval and a trace.