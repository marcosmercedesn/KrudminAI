# Coding-Agent Workflow

This is the operating contract for an agent changing a host application that uses KrudminAI. It is intentionally procedural. Follow it to locate the real owner of a behavior, preserve the engine security boundary, and leave executable proof behind.

## Start Here: First 15 Minutes

Run these checks before editing. Use the host's equivalent commands when `bin/rails` or Minitest is not present.

```sh
pwd
git status --short
find . -maxdepth 2 -type f \( -name 'Gemfile' -o -name 'AGENTS.md' -o -name 'routes.rb' \) -print
bin/rails runner 'puts Rails.application.class.name' 2>/dev/null || true
bin/rails routes 2>/dev/null | head -80 || true
```

Then read, in this order:

1. `AGENTS.md` at the host root. It contains host-specific constraints and the generated KrudminAI instructions.
2. `docs/krudmin_ai/README.md` to understand the generated package.
3. This file, `provider_contracts.md`, and `architecture.md`.
4. The relevant domain blueprint and task file in `docs/krudmin_ai/`.
5. The current resource, model, policy, routes, request/system tests, and host initializer before changing an implemented workflow.

If the host has not installed KrudminAI, stop and use the installation sequence below. Do not invent a parallel integration. If the requested domain has no blueprint or task file, record that as a host-owned design decision before creating application code.

## Host Bootstrap

An installed host should have these engine-managed paths:

| Path                                | Purpose                                            | Ownership                           |
| ----------------------------------- | -------------------------------------------------- | ----------------------------------- |
| `config/initializers/krudmin_ai.rb` | Providers and navigation configuration             | Host, with generated placeholders   |
| `app/resources/`                    | Resource declarations and generated extensions     | Host plus managed generator markers |
| `docs/krudmin_ai/`                  | Generated engine contracts and capability registry | Generator-managed                   |
| `AGENTS.md`                         | Host instructions and generated instruction block  | Host plus managed block             |
| `config/importmap.rb`               | Engine JavaScript pins when using Importmap        | Host plus managed block             |

For a new host using the local engine checkout:

```sh
bundle install
bin/rails generate krudmin_ai:install
bin/rails generate krudmin_ai:docs_sync
```

For a released gem, use the selected released version in the Gemfile, then run the same generators. The installer does not configure host authentication or business authorization for you.

Before enabling a protected resource, replace every provider placeholder with a named host object. All five providers are required:

```ruby
KrudminAI.configure do |config|
	config.authentication_provider = HostAuthenticationProvider.new
	config.tenant_provider = HostTenantProvider.new
	config.authorization_provider = HostAuthorizationProvider.new
	config.audit_provider = HostAuditProvider.new
	config.notification_provider = HostNotificationProvider.new
end
```

Verify provider behavior before building resources: authenticated and anonymous requests, missing tenant, cross-tenant scope, false authorization, malformed results, and raised exceptions must all fail closed. Read `provider_contracts.md` for method signatures and safe results; do not infer provider behavior from a controller or view.

## How To Locate The Owner

Start from the user-visible behavior or failing test and trace inward. Use this order:

1. Route and controller: confirm the endpoint and resource declaration.
2. Resource: inspect model, route key, tenant key, `permit`, list/form/show fields, filters, sorting, relationships, actions, and policies.
3. Access boundary: inspect authentication, tenant provider, authorization scope, record authorization, and field read/write decisions.
4. Shared pipeline: inspect query or mutation code only when the behavior is shared by multiple resources.
5. View or Stimulus controller: change presentation only after the data and authorization path is correct.
6. Tests: find the narrowest request/system test that proves the behavior, then add the denied and cross-tenant case beside it.

Do not fix a shared-pipeline problem in one resource. Do not fix an authorization problem in a view. Do not add a controller action when a declared resource action or transition is the owning abstraction.

## Security Invariants

- Keep admin workflows authenticated by default. Never add a bypass for convenience, development, a seed, or a test fixture.
- Resolve the active tenant from the verified actor or trusted server context. Never accept a tenant identifier from an unverified browser parameter, header, or subdomain.
- Every relation must flow through tenant scope, policy scope, filters, sort, then pagination. Apply this to lists, lookups, exports, dashboards, jobs, and AI context.
- Deny access when a policy answer is absent, malformed, false, or raises. UI visibility and endpoint authorization must use the same `AccessContext` decision.
- Load records through the authorized resource relation or canonical resource lookup. Never trust a record ID merely because it is syntactically valid.
- Route every write through the resource mutation pipeline so validation, field authorization, audit, transaction, and notification behavior remain aligned.
- Treat files, rich text, identifiers, memberships, roles, and personal data as sensitive until an explicit field policy says otherwise.
- Keep AI read-only by default. Provider output is untrusted proposal data, not authority. A write requires reviewed proposal data, explicit approval policy, canonical authorized lookup, normal field authorization, mutation-pipeline execution, and an audit trace.
- Do not put secrets, production exports, session data, personal data, raw AI output, or access tokens in source, tests, fixtures, generated documentation, logs, or the capability registry.

## Implementing A Resource

Prefer the generator for a new resource:

```sh
bin/rails generate krudmin_ai:resource Order --fields number:string status:enum total:decimal placed_on:date
bin/rails db:migrate
```

Then update the generated resource and policy together. A resource is not ready when it merely renders. Supply and test its model, route key, tenant key, permitted fields, list/form/show fields, tenant record check, policy scope, field decisions, and mutation authorization. Generated policy predicates intentionally deny by default.

Use one conventional Rails `resources` route. Declared actions and transitions use the generic member action route; do not add resource-specific controller actions for them. Put action implementations in the generator-managed resource extension location and retain managed markers.

For relationships, require Rails nested attributes where appropriate, scope child records through the parent association, authorize the child operation, and test forged child IDs and cross-tenant IDs. For lookups, use the target resource's authorized relation and test both label-read permission and ID rejection.

For fields, declare an adapter or use safe schema inference only when the adapter contract supports the field. A readable field is not automatically writable. Apply the same field policy to HTML, JSON, CSV, dashboards, and AI context.

## Admin Navigation

Register sidebar links through `KrudminAI.configure`; do not build a parallel host sidebar for engine resources. Use a top-level `navigation_item` for an independent destination and `navigation_group` for one level of related destinations:

```ruby
KrudminAI.configure do |config|
	config.navigation_group(label: "Configuration", icon: :settings) do |group|
		group.navigation_item(label: "Countries", route: :countries_path,
			visible: ->(context) { CountryPolicy.new(context.actor, Country).index? })
		group.navigation_item(label: "Regions", route: :regions_path,
			visible: ->(context) { RegionPolicy.new(context.actor, Region).index? })
	end
end
```

Apply the same policy decision to every child that protects its endpoint. A group is rendered only when its own `visible:` predicate is exactly `true` and at least one child is visible. `nil`, non-true values, and exceptions hide the item or group. Visibility is not authorization. Do not nest groups; use a resource index, dashboard, or host-designed interface for deeper organization.

## Dashboard Widgets

Read `dashboard_widgets.md` before adding or changing a widget. Every widget needs a resource, relation factory, explicit visibility predicate, and declared icon/color. Start the relation from the resource model and let the dashboard base apply the query pipeline. Never calculate protected values in a controller or template, and never use request parameters as icon names or CSS values.

Add focused coverage for visibility, tenant/policy scope, declared filters, pagination where applicable, field read policy, and the selected icon/color.

## Delivery Loop

1. State the smallest behavior change and identify its owning resource or shared abstraction.
2. Name the affected authentication, tenant, policy, field, audit, notification, AI, and UI decisions.
3. Read the current implementation and nearest test before editing. Preserve unrelated host changes.
4. Add or update the narrowest request/system test, including anonymous, denied, cross-tenant, or malformed-provider behavior relevant to the change.
5. Implement through resource metadata, policies, adapters, and shared pipelines. Keep controllers and templates thin.
6. Run the focused test, then the relevant domain suite and system/browser test when UI behavior changed.
7. Run route, migration, registry, and generator-idempotency checks when generated contracts or resources changed.
8. Run `git diff --check`, inspect the diff for secrets and managed-marker churn, and update host-owned documentation and capability evidence.

## Required Proof By Change Type

| Change                     | Minimum evidence                                                                                                                          |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| Install or provider change | Host boots; all five providers validate; anonymous denial; authenticated request; provider nil/false/malformed/exception paths            |
| Resource or query          | Anonymous denial; tenant separation; policy denial; filter/sort/pagination; cross-tenant record rejection                                 |
| Create/update/delete       | Permitted mutation; forbidden mutation; cross-tenant ID rejection; field write denial; audit emission and rollback on audit failure       |
| Relationship or lookup     | Parent and child tenant/policy scope; forged-ID rejection; label-read behavior; child validation retention                                |
| File or rich text          | Contract enabled; denied read/write; permitted upload/render; parameter filtering; safe failure path                                      |
| Role or membership         | Least-privilege policy matrix; UI/server decision parity; audit trail; session or membership boundary behavior                            |
| Navigation                 | Visible and hidden child decisions; active child opens its parent; desktop and mobile behavior; endpoint still denies unauthorized access |
| Dashboard                  | Widget visibility; tenant/policy scope; declared filters; field authorization; empty/error results; icon/color contract                   |
| AI feature                 | Field allowlist; scoped context; trace redaction; provider failure; no write without reviewed approval and mutation trace                 |

## Validation Gates

Use the host's actual test runner. For the generated Rails/Minitest host, the baseline is:

```sh
bin/rails test
bin/rails test:system
bin/rails db:migrate
bin/rails routes -g orders
ruby -rjson -e 'JSON.parse(File.read("docs/krudmin_ai/capability_registry.json"))'
git diff --check
```

For a new or changed generated resource, also run its request test and run the generator a second time. Confirm that managed routes, requires, pins, and markers occur once and that host-authored files are not overwritten. For a docs-only change, confirm application source, routes, dependencies, and initializer checksums are unchanged.

Do not claim a feature is proven merely because engine specs pass. Engine tests prove the engine contract; host request/system tests prove provider bindings, tenant data, policies, routes, templates, and assets in the actual application.

## Generated Files And Documentation

Treat files under `docs/krudmin_ai/`, generated resource markers, managed route blocks, managed import-map pins, and the generated block in `AGENTS.md` as generator-owned. Use the appropriate generator or `bin/rails generate krudmin_ai:docs_sync` rather than hand-editing managed content. Put host-specific decisions, approval records, runbooks, and diagrams outside the generated package.

Update the host capability registry when a capability changes, but never place credentials, tokens, connection strings, personal data, or raw provider output in it. Keep a short host-owned decision record for permissions, retention, imports, and approved AI automation.

## Stop Conditions

Stop and ask for a host decision, or record an explicit blocking issue, when:

- Authentication, tenant, authorization, audit, or notification ownership is unclear.
- A requested behavior needs a broader relation than the tenant/policy pipeline permits.
- A policy or field decision is missing and the only proposed fix is to make it permissive.
- A provider returns a value whose safety or shape is not defined by its contract.
- A generated marker, route, or managed document would need manual replacement.
- A test requires real secrets, production data, or disabling CSRF/authentication.
- The correct owner could be either a resource or shared pipeline and the narrow test cannot distinguish them.

Do not silently work around a stop condition. The useful handoff is the failing command or test, the exact contract that is missing, the affected resource/path, and the smallest host decision needed to continue.

## Admin Navigation

Register sidebar links through `KrudminAI.configure`; do not build a parallel host sidebar for engine resources. Use a top-level `navigation_item` for an independent destination. Use `navigation_group` when related destinations belong beneath one labeled parent. Groups support one parent-to-child level, matching the engine's default sidebar.

```ruby
KrudminAI.configure do |config|
	config.navigation_group(label: "Configuration", icon: :settings) do |group|
		group.navigation_item(label: "Countries", route: :countries_path)
		group.navigation_item(label: "Regions", route: :regions_path)
	end
end
```

- Apply the same policy decision to every child that protects its destination. A group is rendered only when its own `visible:` predicate returns exactly `true` and at least one child is visible.
- `visible:` receives the request `AccessContext`; `nil`, non-true values, and exceptions hide the item or group. Do not use visibility as a substitute for endpoint authorization.
- The default disclosure is keyboard-accessible, opens automatically for an active child, and closes the mobile drawer after a destination is selected. Do not recreate those behaviors with host JavaScript.
- Do not place a group inside another group. For deeper information architecture, use a resource index, dashboard, or explicitly designed host interface.

## Dashboard Widgets

Read `dashboard_widgets.md` before configuring dashboard widgets. Declare each widget's Lucide icon with `icon: :icon_name` and semantic color with `color: :blue`, `:teal`, `:green`, `:amber`, `:orange`, or `:red`; the rendered `WidgetResult` exposes them as `widget.icon` and `widget.color`. Host templates should render `krudmin_ai_icon(widget.icon || widget.resource.icon)` so widgets without an explicit icon retain the resource default.

## Delivery Loop

1. State the smallest behavior change and the owning resource.
2. Name the authorization, tenant, field, audit, and UI decisions affected by the change.
3. Add or update the focused request/system test before declaring the work complete.
4. Implement through resource metadata, policies, adapters, and the shared pipeline. Keep controllers thin.
5. Run the narrow test, then the domain suite. Run `git diff --check` before handoff.
6. Update the host capability registry and the relevant host documentation whenever a capability changes.

## Required Proof By Change Type

| Change                 | Minimum evidence                                                                                                     |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------- |
| Resource or query      | Anonymous denial, tenant separation, policy denial, filter/sort/pagination behavior                                  |
| Create/update/delete   | Permitted mutation, forbidden mutation, cross-tenant ID rejection, audit emission                                    |
| Relationship or lookup | Target tenant/policy scope, forged-ID rejection, label-read behavior, child validation retention                     |
| File or rich text      | Contract enabled, denied read/write behavior, permitted upload/render, parameter filtering                           |
| Role or membership     | Least-privilege policy matrix, UI/server decision parity, audit trail                                                |
| Navigation             | Visible and hidden child decisions, active child keeps its parent group open, desktop and mobile navigation behavior |
| AI feature             | AI field allowlist, scoped context, trace redaction, provider failure, no write without reviewed approval            |

## Useful Commands

```sh
bin/rails generate krudmin_ai:docs_sync
bin/rails test
bin/rails test:system
ruby -rjson -e 'JSON.parse(File.read("docs/krudmin_ai/capability_registry.json"))'
git diff --check
```

Replace or supplement these commands with the host's documented test commands. Keep a short host-owned decision record for permissions, retention, imports, and any approved AI automation.
