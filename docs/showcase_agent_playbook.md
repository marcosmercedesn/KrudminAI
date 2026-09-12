# Showcase Agent Playbook

Use `rails generate krudmin_ai:showcase --mode full` to install the support-operations conformance fixture. Treat it as a conformance example, not a place to bypass security contracts.

1. Read `.krudmin_ai/showcase_manifest.json` and the host `AGENTS.md` before editing generated files.
2. Preserve `ShowcaseTicketsResource` tenant scope, policy scope, tenant record check, filters, and explicit CRUD authorization predicates.
3. Preserve `TicketPolicy` role predicates and tenant comparison for `assign_to_me?` and `resolve?`.
4. Route dashboard queries through `Dashboards::Base`, mutations through declared resource actions and the mutation pipeline, and UI changes through the theme and Hotwire primitives.
5. Run `ruby bin/verify_showcase --host demo` before changing the fixture contract. Add a test for every changed workflow proving authentication, cross-tenant isolation, and policy denial remain intact.