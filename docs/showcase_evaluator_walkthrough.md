# Showcase Evaluator Walkthrough

Run `rails generate krudmin_ai:showcase --mode full` in a host application, run the generated showcase migration, load `db/seeds/krudmin_ai_showcase.rb`, and configure the documented host authentication and provider adapters. The generated policy is self-contained and does not require an `ApplicationPolicy` base class.

1. Sign in as a Northwind support agent and open the showcase tickets resource. Confirm unauthenticated access is rejected.
2. Filter by state or assignee, then verify only Northwind tickets appear. Change the role to manager and confirm the resolve workflow becomes authorized.
3. Use the generated `assign_to_me` and `resolve` action member endpoints to inspect custom-action and state-transition policy predicates. Verify the host mutation adapter emits its audit event.
4. Render the generated lifecycle Count and Table widgets against `ShowcaseTicketsResource`. Confirm Southwind data cannot affect totals or rows.
5. Switch the interface between light, dark, and system modes. Verify keyboard focus is visible and the filter panel receives focus when opened.

`--mode lightweight` omits dashboard and scenario artifacts. The showcase is a conformance fixture, not a whole admin application: host navigation, association editors, and AI setup are intentionally separate responsibilities.

Showcase execution is generated-companion-fixture evidence, not independent generated-host beta proof. Its remaining coverage obligations are assigned in [beta_release_decision.md](beta_release_decision.md).