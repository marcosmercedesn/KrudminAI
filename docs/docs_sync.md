# Documentation Sync Contract

`rails generate krudmin_ai:docs_sync` refreshes the generated package under `docs/krudmin_ai/`, the generated capability registry, and the `KRUDMIN_AI_GENERATED_INSTRUCTIONS` block in the host `AGENTS.md`. `rails generate krudmin_ai:install --docs-only` provides the same operation.

It must not modify runtime application code, routes, initializers, dependencies, migrations, or host files outside the managed instruction block. Re-runs are idempotent. The capability registry preserves host-authored keys while adding generator-owned release, enabled-module, provider-binding-slot, and feature-flag metadata. Generated provider slots must not contain secrets.