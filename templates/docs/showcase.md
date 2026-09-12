# KrudminAI Support Operations Showcase

The showcase models tenant-separated support tickets for Northwind and Southwind. Its ticket resource demonstrates authenticated CRUD, state and assignee filtering, tenant scope, policy scope, mutation auditing, declared actions/transitions, and lifecycle dashboard widgets.

Use `rails generate krudmin_ai:showcase --mode lightweight` for the resource blueprint. Use `--mode full` to add a dashboard and executable request scenario. Run the generated migration and `db/seeds/krudmin_ai_showcase.rb` after installation. Sign in as a Northwind support agent to view and assign Northwind tickets; sign in as a Northwind manager to resolve or delete them. Southwind records must never appear in Northwind results or widget totals.

The fixture proves its generated resource, actions, transition, dashboard relation, audit hook, filters, and tenant/role request paths. Host authentication wiring, navigation presentation, association editors, and AI configuration remain host responsibilities and must be proven by their own scenarios.
