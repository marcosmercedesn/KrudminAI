# Showcase Evaluator Walkthrough

Run `rails generate krudmin_ai:showcase` in a host application, run the generated showcase migration, load `db/seeds/krudmin_ai_showcase.rb`, and configure host authentication plus the required `ApplicationPolicy` base class.

1. Sign in as a Northwind support agent and open the showcase tickets resource. Confirm unauthenticated access is rejected.
2. Filter by state or assignee, then verify only Northwind tickets appear. Change the role to manager and confirm the resolve workflow becomes authorized.
3. Use the generated `assign_to_me` and `resolve` member endpoints to inspect custom-action and state-transition policy predicates. Verify the host mutation adapter emits its audit event.
4. Build Count, Table, and Summary widgets against `ShowcaseTicketsResource`. Confirm Southwind data cannot affect totals.
5. Switch the interface between light, dark, and system modes. Verify keyboard focus is visible and the filter panel receives focus when opened.

The showcase is a host-app blueprint. It intentionally leaves provider wiring and Rails controller integration to the host application's configured adapters.