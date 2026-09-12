# Showcase Agent Playbook

Use `rails generate krudmin_ai:showcase` to install the support-operations blueprint. Treat it as a conformance example, not a place to bypass security contracts.

1. Read `.krudmin_ai/showcase_manifest.json` and the host `AGENTS.md` before editing generated files.
2. Preserve `ShowcaseTicketsResource` tenant scope, policy scope, tenant record check, filters, and explicit CRUD authorization predicates.
3. Preserve `TicketPolicy` role predicates and tenant comparison for `assign_to_me?` and `resolve?`.
4. Route dashboard queries through the widget APIs, mutations through the mutation pipeline and audit sink, and UI changes through the theme and Hotwire primitives.
5. Add a test for every changed workflow proving authentication, cross-tenant isolation, and policy denial remain intact.