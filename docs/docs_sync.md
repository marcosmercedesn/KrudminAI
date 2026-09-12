# Documentation Sync Contract

The future install generator will place a versioned package under `docs/krudmin_ai/` in host applications and write an AI instruction file at the host-app root.

The future `docs-sync` generator updates only that package, the generated capability registry, and the generated instruction file. It must not modify runtime application code, routes, initializers, or dependency manifests. Re-runs must be idempotent and preserve host-authored content outside generated markers.