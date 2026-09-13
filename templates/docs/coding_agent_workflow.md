# Coding-Agent Workflow

This document is the operating contract for agents changing this host application. It turns KrudminAI's security guarantees into a repeatable delivery process.

## Required Reading Order

1. Read this file and `provider_contracts.md` before changing authentication, tenancy, authorization, mutations, or audit behavior.
2. Read the domain blueprint before creating a resource, migration, route, or view for that domain.
3. Read the matching task before editing; complete its acceptance checks before marking it done.
4. Read the current resource, policy, model, request tests, and relevant browser tests before changing an implemented workflow.

## Non-Negotiable Rules

- Keep admin workflows authenticated by default. Do not add a bypass for convenience, development, or a test fixture.
- Resolve the active tenant from the verified actor or trusted server context. Never accept a tenant identifier from an unverified browser parameter.
- Every relation must flow through tenant scope, policy scope, filters, sort, then pagination. Do not query models directly from a controller, view, job, export, dashboard, lookup, or AI provider path.
- Deny access when a policy answer is absent, malformed, or false. UI visibility and server-side authorization must use the same decision.
- Route every write through the resource mutation pipeline so validation, field authorization, audit, and notification behavior remain aligned.
- Treat files, rich text, identifiers, memberships, roles, and personal data as sensitive until an explicit field policy says otherwise.
- Keep AI read-only. Provider output is untrusted proposal data, not authority. A write needs a reviewed proposal, explicit approval policy, canonical record lookup, normal field authorization, mutation pipeline execution, and audit trace.
- Do not put secrets, production exports, session data, personal data, raw AI output, or access tokens in source, tests, fixtures, generated documentation, logs, or the capability registry.

## Delivery Loop

1. State the smallest behavior change and the owning resource.
2. Name the authorization, tenant, field, audit, and UI decisions affected by the change.
3. Add or update the focused request/system test before declaring the work complete.
4. Implement through resource metadata, policies, adapters, and the shared pipeline. Keep controllers thin.
5. Run the narrow test, then the domain suite. Run `git diff --check` before handoff.
6. Update the host capability registry and the relevant host documentation whenever a capability changes.

## Required Proof By Change Type

| Change | Minimum evidence |
| --- | --- |
| Resource or query | Anonymous denial, tenant separation, policy denial, filter/sort/pagination behavior |
| Create/update/delete | Permitted mutation, forbidden mutation, cross-tenant ID rejection, audit emission |
| Relationship or lookup | Target tenant/policy scope, forged-ID rejection, label-read behavior, child validation retention |
| File or rich text | Contract enabled, denied read/write behavior, permitted upload/render, parameter filtering |
| Role or membership | Least-privilege policy matrix, UI/server decision parity, audit trail |
| AI feature | AI field allowlist, scoped context, trace redaction, provider failure, no write without reviewed approval |

## Useful Commands

```sh
bin/rails generate krudmin_ai:docs_sync
bin/rails test
bin/rails test:system
ruby -rjson -e 'JSON.parse(File.read("docs/krudmin_ai/capability_registry.json"))'
git diff --check
```

Replace or supplement these commands with the host's documented test commands. Keep a short host-owned decision record for permissions, retention, imports, and any approved AI automation.