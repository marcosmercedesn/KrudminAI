# KrudminAI Implementation Prompts

This file is the task index for the repo. You do not need to copy/paste the whole prompt body. You can simply reference the relevant task by number, stage name, or short alias, and then tell the agent: “do 1”, “do next”, “start”, or “continue”.

## Quick task map

- 1 — Generic Resource Delivery and Generated-Host Conformance
- 2 — Provider Contracts and Security Baseline
- 3 — Format Delivery and Durable Audit
- 4 — Documentation and Capability Registry Maintenance
- 5 — Next-Slice Planner for the Product Roadmap
- 6 — Focused Regression Check Before Any New Feature Work

## Short aliases

- “start” = run task 1
- “do 1” = run task 1
- “next” = run the next uncompleted task in sequence
- “continue” = run the next task in sequence
- “do 2” / “do 3” / etc. = specific task
- “baseline” = run task 6
- “plan next” = run task 5
- “docs” = run task 4

## How to use this file

When you want the agent to proceed, use one of these patterns:

- “Do 1.”
- “Start with task 2.”
- “Do next.”
- “Continue with the next slice.”
- “Run the baseline check.”
- “Plan the next slice.”
- “Do docs update for the current implementation.”

The agent should resolve the task by reading this file, locating the matching numbered section below, and executing only that section’s scope.

Important ground rules for all prompts:
- Read and honor [AGENTS.md](../AGENTS.md) first.
- Read the relevant docs before changing behavior: [docs/architecture.md](architecture.md), [docs/beta_readiness_checkpoint.md](beta_readiness_checkpoint.md), and the capability docs touched by the slice.
- Preserve the core invariant: authentication required by default, tenant scope before policy scope before filtering, sorting and pagination, deny-by-default authorization, and read-only AI unless explicit approval.
- Update tests, docs, and [docs/capability_registry.json](capability_registry.json) when capability behavior changes.
- Do not drift into unrelated improvements or speculative architecture changes.

---

## Task 1: Generic Resource Delivery and Generated-Host Conformance

You are working in the KrudminAI Rails engine repository. Your task is to implement the first beta-blocking slice called out in [docs/beta_readiness_checkpoint.md](beta_readiness_checkpoint.md): generic resource delivery and generated-host conformance.

Context:
- The project is currently on a beta hold because the engine has strong contracts but still does not provide generic secured CRUD behavior end to end without resource-specific host controller or view logic.
- The repo already includes the foundational resource contract, query access pipeline, mutation pipeline, and a runnable demo app, but the generic render surface is not fully implemented.
- The intended product boundary is: a host declares a resource and routes it conventionally, while KrudminAI provides secure CRUD behavior and default rendering.
- This slice must not become a dashboard, AI, or provider redesign project.

Goal:
- Extend the resource contract with minimal presentational metadata needed for default list, form, and show rendering.
- Add engine-owned generic templates or components for index, form, and show pages using generic `model`, `models`, and route helpers.
- Make generated resources use those defaults while preserving host override capability.
- Reduce or remove the need for demo resource-specific templates unless they are intentionally overriding defaults.
- Add a disposable/generated Rails-host integration proof that confirms security, tenant scoping, denied cross-tenant access, CRUD behavior, and default rendering.

Primary files to inspect first:
- [lib/krudmin_ai/resource_controller.rb](../lib/krudmin_ai/resource_controller.rb)
- [lib/krudmin_ai/resources/base.rb](../lib/krudmin_ai/resources/base.rb)
- [lib/krudmin_ai/generators/resource_contract.rb](../lib/krudmin_ai/generators/resource_contract.rb)
- [demo/app/resources/tickets_resource.rb](../demo/app/resources/tickets_resource.rb)
- [demo/app/views/tickets](../demo/app/views/tickets)
- [demo/test/integration/ticket_access_test.rb](../demo/test/integration/ticket_access_test.rb)
- [docs/beta_readiness_checkpoint.md](beta_readiness_checkpoint.md)
- [docs/architecture.md](architecture.md)

Scope:
- Add the minimal resource metadata needed for generic rendering (at least labels and fields for list/form/show contexts).
- Implement generic CRUD view delivery in the engine without introducing a broad field-type framework unless strictly necessary.
- Ensure the default controller path uses generic route helpers such as `collection_path`, `resource_path`, `new_resource_path`, and `edit_resource_path`.
- Keep the host override path explicit and optional, not required.
- Add generated-host request tests proving constrained behavior across at least two tenants and two roles.

Non-goals:
- No dashboard work.
- No provider redesign.
- No new AI capabilities.
- No broad custom action system.
- No large field framework redesign unless absolutely required for the first generic renderer.

Acceptance criteria:
1. A generated `OrdersResource` and thin `OrdersController` boots in a Rails host with conventional `resources :orders` routing.
2. Default engine views render index/new/edit/show without host-specific resource templates.
3. The default form uses the resource permit list and generic route helpers.
4. Layout and engine/host stylesheet contract are present in the HTTP response.
5. Request tests prove security and CRUD behavior across at least two tenants and two roles.
6. A focused browser/system test covers list -> edit -> submit using the selected stable driver.

Required validation:
- Run the generator contract spec.
- Run the current companion request suite for ticket access.
- Ensure JSON parsing remains valid for capability registry changes.
- Run `git diff --check` at the end.

Deliverables:
- Code changes implementing generic CRUD rendering and generated-host conformance.
- Tests proving tenant/role and CRUD security behavior.
- Updated docs and capability registry if the capability changes.

---

## Task 2: Provider Contracts and Security Baseline

You are implementing the second beta-blocking slice from [docs/beta_readiness_checkpoint.md](beta_readiness_checkpoint.md): provider contracts and the security baseline.

Context:
- The project already contains provider configuration hooks and access-context patterns, but they are not yet formalized enough to count as a robust security baseline.
- The risk is that provider misconfiguration can silently broaden access or fail in unsafe ways.
- The beta checkpoint explicitly calls for executable authentication, authorization, tenant, audit, and notification adapter interfaces with clear failure behavior and documentation.

Goal:
- Define concrete provider contracts that the engine can validate at boot.
- Add or harden adapter interfaces for authentication, authorization, tenant resolution, audit logging, and notifications.
- Make failures fail closed with clear configuration errors.
- Document the security model for sessions, cookies, CSRF, headers, and sensitive-data handling.

Primary files and docs to inspect:
- [lib/krudmin_ai/resource_controller.rb](../lib/krudmin_ai/resource_controller.rb)
- [lib/krudmin_ai/resources/base.rb](../lib/krudmin_ai/resources/base.rb)
- [docs/architecture.md](architecture.md)
- [docs/compatibility_policy.md](compatibility_policy.md)
- [docs/product_scope.md](product_scope.md)
- [docs/beta_readiness_checkpoint.md](beta_readiness_checkpoint.md)

Scope:
- Define provider interfaces and validation semantics.
- Add tests for invalid or missing provider configs.
- Use fail-closed behavior and explicit configuration errors rather than silent fallback.
- Document the security baseline in a way that is concrete enough for generated apps.

Non-goals:
- No new dashboard features.
- No generic CRUD rendering work in this prompt unless needed to validate provider contracts.
- No experimental AI provider deepening.
- No large UI redesign.

Acceptance criteria:
1. Providers have a clear interface contract and boot-time validation behavior.
2. Missing or invalid config fails safely and predictably.
3. Security baseline documentation covers CSRF, sessions, cookies, headers, and sensitive-data handling.
4. Tests cover at least one success path and one fail-closed path for each core provider contract.

Validation:
- Run the relevant unit tests for provider/config behavior.
- Confirm the engine remains bootable in the demo host.
- Update docs and capability registry entries if provider behavior changes.

---

## Task 3: Format Delivery and Durable Audit

You are implementing the third beta-blocking slice from [docs/beta_readiness_checkpoint.md](beta_readiness_checkpoint.md): format delivery and durable audit.

Context:
- The mutation pipeline exists, but the full response contract is not proven end to end.
- HTML is partially covered in the generic controller, but JSON and Turbo Stream delivery are not yet wired and validated through request-level evidence.
- The audit system exists in the demo but has not yet been hardened to guarantee durable semantics and recovery handling.

Goal:
- Wire the response adapter through the controller and resource flow for HTML, JSON, and Turbo Stream responses.
- Verify that mutation results and errors are normalized consistently across formats.
- Add a transaction-aware audit or outbox-style persistence contract with failure/recovery tests.
- Keep the change scoped to format delivery and durable audit semantics, not unrelated platform features.

Primary files and docs to inspect:
- [docs/mutation_pipeline.md](mutation_pipeline.md)
- [docs/beta_readiness_checkpoint.md](beta_readiness_checkpoint.md)
- [lib/krudmin_ai/resource_controller.rb](../lib/krudmin_ai/resource_controller.rb)
- the mutation pipeline implementation under [lib/krudmin_ai](../lib/krudmin_ai)
- demo test coverage for ticket access and mutation flows

Scope:
- Add or improve response adapters for created/updated/destroyed records.
- Validate the controller-level integration for all required formats.
- Introduce durable audit semantics in a way consistent with the engine’s architecture.
- Include failure behavior and recovery tests.

Non-goals:
- No showcase expansion.
- No new AI capabilities.
- No dashboard work.
- No broad UI rewrite.

Acceptance criteria:
1. HTML, JSON, and Turbo Stream response behavior is exercised through request tests.
2. Mutation failures and authorization denials return consistent structured results.
3. Audit persistence is durable enough to satisfy the operation’s contract and recover correctly when audit writing fails or is retried.
4. The engine documentation reflects the format and audit guarantees.

Validation:
- Run the relevant request and mutation pipeline tests.
- Confirm no regressions in the demo app request suite.
- Update docs and the capability registry if response or audit capability semantics change.

---

## Task 4: Documentation and Capability Registry Maintenance for the Current Slice

You are updating the KrudminAI docs and capability registry to match the implementation work completed in the current slice.

Context:
- The project explicitly requires docs and capability metadata to be updated with each capability change.
- The beta checkpoint is a living product gate and must reflect actual Rails-host evidence, not just unit-contract confidence.
- Documentation drift is a project risk; keep the docs faithful to implementation reality.

Goal:
- Update the relevant docs for the slice you just implemented.
- Ensure the capability registry reflects the real operational state of the engine.
- Keep the beta checkpoint accurate to the actual implementation status.

Files to update as relevant:
- [docs/architecture.md](architecture.md)
- [docs/generators.md](generators.md)
- [docs/beta_readiness_checkpoint.md](beta_readiness_checkpoint.md)
- [docs/capability_registry.json](capability_registry.json)
- any other docs directly impacted by the slice

Scope:
- Update architectural, generator, and capability docs to describe implemented behavior accurately.
- Do not mark a capability as fully implemented without Rails-host evidence.
- Reconcile the docs with actual runtime behavior and test coverage.

Non-goals:
- No new product scope or speculative features.
- No unrelated cleanup.
- No marketing copy or roadmap expansion.

Acceptance criteria:
1. The docs reflect implemented behavior precisely.
2. The registry matches the code and test evidence.
3. The beta checkpoint is not overstating product readiness.

Validation:
- Parse the JSON registry after changes.
- Run `git diff --check`.
- Review the docs for mismatches with the implementation and the checkpoint.

---

## Task 5: Next-Slice Planner for the Product Roadmap

You are planning the next slice after the generic CRUD / generated-host conformance work is complete.

Context:
- The project has a valid roadmap sequence: generic CRUD first, then provider/security baseline, then format delivery and durable audit, and only then broader UI/dashboard/AI expansion.
- The repo contains a strong product and architecture vision, and the beta checkpoint defines deferred work after those foundational slices.

Goal:
- Produce a concise, execution-ready plan for the next slice after the current one.
- Keep the plan grounded in the checkpoint, not in speculative feature expansion.

Use the following as authority:
- [docs/beta_readiness_checkpoint.md](beta_readiness_checkpoint.md)
- [docs/architecture.md](architecture.md)
- [docs/rails8_replacement_inventory.md](rails8_replacement_inventory.md)
- [AGENTS.md](../AGENTS.md)

Scope:
- Propose the next slice in the same priority order and with the same constraints as the checkpoint.
- Include objective, scope, non-goals, acceptance criteria, likely files, and a validation checklist.

Non-goals:
- Do not skip ahead to dashboards, import/export, observability, or AI heavy features before the foundational slices are proven.

Deliverable:
- A short plan in the same format as the beta checkpoint’s “Slice 1 / Slice 2 / Slice 3” structure.

---

## Task 6: Focused Regression Check Before Any New Feature Work

You are preparing the repo for the next feature slice and must perform a focused regression check before continuing.

Context:
- A new slice should not start without verifying the current engine and demo host are in a known-good state.
- This repository has a demo app and generator contract suite; use those as the current evidence baseline.

Goal:
- Confirm the current baseline and identify any regression risks before implementation.
- Keep the run narrow and relevant to the current slice rather than executing broad suites unnecessarily.

Files and commands to use as needed:
- [docs/beta_readiness_checkpoint.md](beta_readiness_checkpoint.md)
- [AGENTS.md](../AGENTS.md)
- relevant generator specs and demo integration tests

Scope:
- Check the current contract and demo test baseline.
- Confirm expected behavior before introducing changes.
- Identify the exact files most likely to be touched by the current slice.

Non-goals:
- No unrelated cleanup.
- No speculative changes.

Deliverable:
- A brief regression summary with: current passing evidence, notable gaps, and recommended next slice entry point.

---

## Recommended order to use these tasks

1. Task 6: baseline regression check (alias: baseline)
2. Task 1: generic resource delivery and generated-host conformance (alias: start / do 1)
3. Task 2: provider contracts and security baseline (alias: do 2)
4. Task 3: format delivery and durable audit (alias: do 3)
5. Task 4: docs and capability registry update (alias: docs)
6. Task 5: plan the next slice after the current base is green (alias: plan next)

This is the ordered execution sequence. Use “start”, “do 1”, “do next”, or “continue” to move through it without copy/pasting the full prompt text.
