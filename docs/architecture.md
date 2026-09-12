# Architecture

KrudminAI is an isolated Rails engine for authenticated back-office workflows. It uses Propshaft-native assets and module-based Hotwire interactions with Turbo and Stimulus. jQuery is excluded from runtime and test dependencies.

The canonical query pipeline is tenant scope, policy scope, filters, sort, pagination. Every list, search, export, dashboard, and AI context builder must use it. The implemented resource and pipeline contracts are documented in [resource_query_pipeline.md](resource_query_pipeline.md). The mutation pipeline dispatches create, update, and destroy through tenant and action authorization, normalized results, response adapters, and required audit hooks; see [mutation_pipeline.md](mutation_pipeline.md). Transitions and custom actions remain future work.

`KrudminAI::ResourceController` owns conventional CRUD delivery for a resource: authentication via configured providers, access-context creation, tenant/policy-scoped query composition, generic `model` and `models` assignment, secure model lookup, permitted attributes, create/update/destroy dispatch, audit sink resolution, and generic route helpers (`collection_path`, `resource_path`, `new_resource_path`, and `edit_resource_path`). A host controller inherits it and declares only `resource OrdersResource`. The resource declares its model, route key, tenant key, permitted attributes, scopes, filters, sorting, and authorization predicates. Rails retains one conventional `resources :orders` route registration, which the resource generator manages idempotently.

Field adapters will render deterministically for form, list, show, search, and JSON contexts. UI affordances use the same policy decisions as their endpoints. Provider failures deny access or stop the operation; they never silently broaden access.

AI context comes only from policy-authorized, tenant-scoped data with approved field allowlists. AI is suggestion-only by default. Mutations require explicit approval and a trace. The implemented assistant contract supports record summaries, record Q and A, document summaries, and report insights; see [ai_assistant.md](ai_assistant.md).

The UI foundation is Hotwire-first: engine-owned CSS tokens, light/dark/system theme selection, and Stimulus controllers support accessible resource tables, filters, and form shells. See [ui_foundations.md](ui_foundations.md).

Install and resource generators use idempotent file contracts. Generated resources preserve authentication, tenant checks, policy scope, deny-by-default action predicates, and matching request-test scaffolds. The docs-only generator mode is restricted to generated documentation and AI instruction artifacts; see [generators.md](generators.md).

Dashboard widgets use the query access pipeline before aggregation or rendering. Count and summary widgets use the authorized relation; table widgets use the complete sorted and paginated path. See [dashboards.md](dashboards.md).