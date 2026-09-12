# KrudminAI Kickoff Prompt Pack

Use this prompt pack when starting KrudminAI from an empty folder.

## Workspace Preparation

1. Open your new empty KrudminAI folder in VS Code.
2. Copy `docs/rails8_replacement_inventory.md` from this repo into your new project under `docs/rails8_replacement_inventory.md`.
3. Add `/Users/mamerced/projects/krudmin/` as an additional workspace folder so local references are accessible.
4. Start with Prompt 1 below.

## Global Discipline Block

Append this block to every prompt in this pack.

```text
Execution Discipline Requirements:
- Do not jump ahead to large rewrites.
- Deliver one vertical slice at a time with green tests.
- If any requirement is ambiguous, propose assumptions and proceed with the safest default aligned to docs/rails8_replacement_inventory.md.
- Use only local references from /Users/mamerced/projects/krudmin/ unless I explicitly approve internet sourcing.
- Keep implementation modular and upgrade-friendly for future Rails and Ruby versions.
- Treat UI/UX quality as a release-critical requirement: premium smooth interactions, consistent visual hierarchy, meaningful motion, and accessibility parity in light and dark modes.
- Add tests and docs updates in the same slice as code changes.
- After each slice, report: changed files, test results, open risks, and 3 numbered next options.
```

## Prompt 1: Project Bootstrap (Phase 1 Start)

```text
Build KrudminAI from zero in this empty folder, using docs/rails8_replacement_inventory.md as the source of truth.
Use /Users/mamerced/projects/krudmin/ as local reference only.
Do not pull implementation details from the internet unless I explicitly approve.

Create the initial project skeleton and baseline contracts:
1) repository structure for a Rails-engine-based project,
2) compatibility policy document (forward-compatible Rails/Ruby support policy, not hardcoded to one version),
3) initial architecture docs for admin-panel-first goals,
4) CI matrix scaffold covering minimum/stable/latest and preview lanes,
5) testing scaffold,
6) AI-instruction and docs-sync scaffolding placeholders.

Then run tests/lint (if available), and report status plus the next smallest vertical slice.

Execution Discipline Requirements:
- Do not jump ahead to large rewrites.
- Deliver one vertical slice at a time with green tests.
- If any requirement is ambiguous, propose assumptions and proceed with the safest default aligned to docs/rails8_replacement_inventory.md.
- Use only local references from /Users/mamerced/projects/krudmin/ unless I explicitly approve internet sourcing.
- Keep implementation modular and upgrade-friendly for future Rails and Ruby versions.
- Add tests and docs updates in the same slice as code changes.
- After each slice, report: changed files, test results, open risks, and 3 numbered next options.
```

## Prompt 2: Core Resource Contract + Access Pipeline

```text
Proceed with the next vertical slice.
Implement the core resource contract and query access pipeline with strict admin security defaults:
1) tenant scope,
2) authorization policy scope,
3) filters,
4) sort,
5) pagination.

Requirements:
- Authentication required by default for generated admin resources.
- Authorization deny-by-default behavior.
- Multi-role and multi-tenant constraints represented in code contracts and tests.
- Include minimal docs and examples for this slice.

Run tests and report status.

Execution Discipline Requirements:
- Do not jump ahead to large rewrites.
- Deliver one vertical slice at a time with green tests.
- If any requirement is ambiguous, propose assumptions and proceed with the safest default aligned to docs/rails8_replacement_inventory.md.
- Use only local references from /Users/mamerced/projects/krudmin/ unless I explicitly approve internet sourcing.
- Keep implementation modular and upgrade-friendly for future Rails and Ruby versions.
- Add tests and docs updates in the same slice as code changes.
- After each slice, report: changed files, test results, open risks, and 3 numbered next options.
```

## Prompt 3: CRUD Mutation Pipeline + Response Contract

```text
Proceed with the next vertical slice.
Implement a minimal mutation pipeline (create/update/destroy) with consistent response behavior for HTML, JSON, and Turbo Stream.

Requirements:
- Explicit authorization checks on mutation endpoints.
- Error taxonomy and normalized response envelope.
- Audit hook interfaces for sensitive actions.
- Tests that verify success and failure paths.

Run tests and report status.

Execution Discipline Requirements:
- Do not jump ahead to large rewrites.
- Deliver one vertical slice at a time with green tests.
- If any requirement is ambiguous, propose assumptions and proceed with the safest default aligned to docs/rails8_replacement_inventory.md.
- Use only local references from /Users/mamerced/projects/krudmin/ unless I explicitly approve internet sourcing.
- Keep implementation modular and upgrade-friendly for future Rails and Ruby versions.
- Add tests and docs updates in the same slice as code changes.
- After each slice, report: changed files, test results, open risks, and 3 numbered next options.
```

## Prompt 4: Hotwire-First UI Foundations

```text
Proceed with the next vertical slice.
Add frontend foundations for admin workflows using Hotwire-first patterns (Turbo + Stimulus, no jQuery).

Requirements:
- Define theme tokens and implement light, dark, and system mode support.
- Implement initial UI primitives for list/table, filter panel, and form shell.
- Accessibility baseline for keyboard navigation and focus visibility.

Run tests and report status.

Execution Discipline Requirements:
- Do not jump ahead to large rewrites.
- Deliver one vertical slice at a time with green tests.
- If any requirement is ambiguous, propose assumptions and proceed with the safest default aligned to docs/rails8_replacement_inventory.md.
- Use only local references from /Users/mamerced/projects/krudmin/ unless I explicitly approve internet sourcing.
- Keep implementation modular and upgrade-friendly for future Rails and Ruby versions.
- Add tests and docs updates in the same slice as code changes.
- After each slice, report: changed files, test results, open risks, and 3 numbered next options.
```

## Prompt 5: Generator Suite (Install + Resource)

```text
Proceed with the next vertical slice.
Implement generator support for:
1) install generator,
2) resource generator,
3) docs-sync mode.

Requirements:
- Install generator scaffolds initializer, AI instructions file, and docs package.
- Resource generator scaffolds resource contract, controller, policy stub, routes, and tests.
- Docs-sync mode updates docs only in host app.
- Generator contract tests required.

Run tests and report status.

Execution Discipline Requirements:
- Do not jump ahead to large rewrites.
- Deliver one vertical slice at a time with green tests.
- If any requirement is ambiguous, propose assumptions and proceed with the safest default aligned to docs/rails8_replacement_inventory.md.
- Use only local references from /Users/mamerced/projects/krudmin/ unless I explicitly approve internet sourcing.
- Keep implementation modular and upgrade-friendly for future Rails and Ruby versions.
- Add tests and docs updates in the same slice as code changes.
- After each slice, report: changed files, test results, open risks, and 3 numbered next options.
```

## Prompt 6: Dashboards + Widget Contract

```text
Proceed with the next vertical slice.
Implement dashboard foundations with policy-aware and tenant-aware widgets.

Requirements:
- First-party widgets: count, table, and summary.
- Widget query path must use tenant scope and policy scope.
- No aggregate leakage across unauthorized scopes.
- Include tests and a short guide for adding custom widgets.

Run tests and report status.

Execution Discipline Requirements:
- Do not jump ahead to large rewrites.
- Deliver one vertical slice at a time with green tests.
- If any requirement is ambiguous, propose assumptions and proceed with the safest default aligned to docs/rails8_replacement_inventory.md.
- Use only local references from /Users/mamerced/projects/krudmin/ unless I explicitly approve internet sourcing.
- Keep implementation modular and upgrade-friendly for future Rails and Ruby versions.
- Add tests and docs updates in the same slice as code changes.
- After each slice, report: changed files, test results, open risks, and 3 numbered next options.
```

## Prompt 7: Showcase Admin Panel (Pivotal)

```text
Proceed with the next vertical slice.
Implement the showcase admin panel generator and demo data so both humans and AI agents can learn KrudminAI capabilities.

Showcase must demonstrate:
- CRUD
- search and filtering
- role-based and tenant-scoped access
- custom actions
- state transitions
- dashboard summaries
- audit trail hooks
- light/dark/system theming

Requirements:
- Add walkthrough docs for human evaluators.
- Add walkthrough scripts/instructions for AI coding agents.
- Add CI checks so showcase remains aligned with platform capabilities.

Run tests and report status.

Execution Discipline Requirements:
- Do not jump ahead to large rewrites.
- Deliver one vertical slice at a time with green tests.
- If any requirement is ambiguous, propose assumptions and proceed with the safest default aligned to docs/rails8_replacement_inventory.md.
- Use only local references from /Users/mamerced/projects/krudmin/ unless I explicitly approve internet sourcing.
- Keep implementation modular and upgrade-friendly for future Rails and Ruby versions.
- Add tests and docs updates in the same slice as code changes.
- After each slice, report: changed files, test results, open risks, and 3 numbered next options.
```

## Prompt 8: In-App Conversational AI Assistant

```text
Proceed with the next vertical slice.
Implement the in-app conversational AI assistant foundation for authenticated users.

Requirements:
- Build a prompt interface that supports record summary, record Q and A, document summary, and report insight hints.
- Enforce role, policy, and tenant boundaries identical to the standard UI access model.
- Default to read-only suggestions.
- Add explicit approval gates for any mutation-capable AI operation.
- Implement trace logging for actor, prompt template, model/provider, scoped context fingerprint, output, and resulting action references.
- Add tests for unauthorized data blocking, tenant isolation, and unsafe tool-call rejection.

Run tests and report status.

Execution Discipline Requirements:
- Do not jump ahead to large rewrites.
- Deliver one vertical slice at a time with green tests.
- If any requirement is ambiguous, propose assumptions and proceed with the safest default aligned to docs/rails8_replacement_inventory.md.
- Use only local references from /Users/mamerced/projects/krudmin/ unless I explicitly approve internet sourcing.
- Keep implementation modular and upgrade-friendly for future Rails and Ruby versions.
- Add tests and docs updates in the same slice as code changes.
- After each slice, report: changed files, test results, open risks, and 3 numbered next options.
```

## Prompt 9: Beta Readiness Gate

```text
Run a beta-readiness checkpoint against docs/rails8_replacement_inventory.md Specification Gates.

Deliver:
1) gap analysis by gate item,
2) prioritized backlog for missing items,
3) risk list,
4) recommendation to proceed or hold,
5) exact next 3 implementation slices.

Execution Discipline Requirements:
- Do not jump ahead to large rewrites.
- Deliver one vertical slice at a time with green tests.
- If any requirement is ambiguous, propose assumptions and proceed with the safest default aligned to docs/rails8_replacement_inventory.md.
- Use only local references from /Users/mamerced/projects/krudmin/ unless I explicitly approve internet sourcing.
- Keep implementation modular and upgrade-friendly for future Rails and Ruby versions.
- Add tests and docs updates in the same slice as code changes.
- After each slice, report: changed files, test results, open risks, and 3 numbered next options.
```
