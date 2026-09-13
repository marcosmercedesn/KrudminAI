# KrudminAI Agent Instructions

Read `docs/` before changing behavior. Preserve these invariants:

- Admin workflows require authentication by default.
- Every data query applies tenant scope, policy scope, filters, sort, then pagination.
- Authorization denies by default; UI behavior uses the same decision.
- AI features are read-only unless an explicit approval policy authorizes a traced mutation.
- Update tests, docs, and `docs/capability_registry.json` with each capability change.
- Use local `../krudmin` only as a behavioral reference; do not copy its jQuery-era architecture.
- Configure engine sidebar destinations through `KrudminAI.configure`. Use `navigation_group` for one-level related destinations, apply the endpoint's `AccessContext` visibility decision to every child, and do not create nested groups or a parallel host sidebar for engine resources.