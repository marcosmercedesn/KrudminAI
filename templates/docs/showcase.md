# KrudminAI Support Operations Showcase

The showcase models tenant-separated support tickets for Northwind and Southwind. Its ticket resource demonstrates authenticated CRUD, state and assignee filtering, tenant scope, policy scope, mutation auditing, and dashboard widgets. The workflow service authorizes `assign_to_me?` and `resolve?` before sending state updates through the audited mutation pipeline.

Run the showcase seed file after installing the generator. Sign in as a Northwind support agent to view and assign Northwind tickets; sign in as a Northwind manager to resolve or delete them. Southwind records must never appear in Northwind results or widget totals.