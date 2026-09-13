# KrudminAI

**KrudminAI is a secure, Hotwire-first Rails engine for authenticated admin applications.**

It provides a resource-driven foundation for internal tools where tenant isolation, authorization, auditability, and data handling need to be part of the framework contract, not conventions each host application must recreate.

KrudminAI is a modern successor direction to [Krudmin](../krudmin), the production-proven Rails admin framework that has supported enterprise applications for more than a decade. It preserves the value of resource-oriented administration while making security boundaries, tenant scoping, audit behavior, and AI integration explicit.

> **Release status:** `0.1.0.pre.1` is in beta readiness work. The current release decision is **hold** while independent generated-host and browser evidence accumulates. See [the beta release decision](docs/beta_release_decision.md).

## Why KrudminAI

- **Secure by construction:** authentication, tenant, authorization, audit, and notification providers are validated at boot and fail closed.
- **One protected query path:** list, search, export, dashboard, lookup, and AI context all apply tenant scope, policy scope, filters, sort, and pagination in that order.
- **Policy-aware fields:** field read, write, and sensitive-value reveal decisions control HTML, JSON, CSV, dashboard, and AI output.
- **Audited mutations:** creates, updates, deletes, archive operations, and declared actions run through one transactional mutation pipeline. A failed audit write rolls back the mutation.
- **Modern Rails UI:** Turbo, Stimulus, Propshaft, responsive resource pages, accessible nested editors, Lucide icons, and light/dark/system themes. No jQuery dependency.
- **Deliberate AI:** scoped, read-only assistance is the default. Any mutation requires an explicit approval policy and a traceable path through the normal mutation pipeline.

## Capabilities

| Area | Included capabilities |
| --- | --- |
| Resources | Generic index, new, edit, show, CRUD routes, labels, icons, sections, eager loading, archive lifecycle, and policy-aware one-level sidebar groups |
| Fields | String, text, email, password, hidden, number, decimal, currency, percentage, boolean, date, time, datetime, JSON, enum, identifier, masked, rich text, image, file, computed, and relationship adapters |
| Relationships | Protected local and remote belongs-to lookup; tenant-checked `has_one` and `has_many` nested editors; protected multi-select IDs |
| Discovery | Explicit typed filters, whitelisted sorting, bounded pagination, protected lookup endpoints, collapsible filter UI |
| Workflows | Declared record/list actions, guarded transitions, confirmation and HTTP-method metadata, bulk operations, constrained inline editing |
| Data operations | Field-aware CSV export, preview/commit imports, explicit profiles, idempotency contracts, sensitive-field masks |
| Dashboards | Count, summary, table, and chart widgets with deny-by-default visibility and protected drill-downs |
| AI | Record summaries, record Q&A, document summaries, report insights, review drafts, traced provider routing, approval-gated automation contracts |

The machine-readable capability inventory is maintained in [docs/capability_registry.json](docs/capability_registry.json).

## Install In A Host Application

### Requirements

- Ruby `>= 3.3`
- Rails `>= 8.1, < 10.0`
- A Rails host application using Turbo, Stimulus, and Propshaft

### 1. Create A Rails Host

For a new application, create a Rails host with Importmap. The example uses PostgreSQL; choose the database adapter that fits the host's operational requirements.

```sh
rails new admin --database=postgresql --javascript=importmap
cd admin
```

### 2. Add KrudminAI

While developing against this checkout, add the local engine path to the host application's `Gemfile`:

```ruby
gem "krudmin_ai", path: "../KrudminAI"
```

When using a released package instead, replace the local path declaration with the selected published version:

```ruby
gem "krudmin_ai", "~> 0.1.0.pre"
```

Install dependencies, then generate the engine-managed host contracts:

```sh
bundle install
bin/rails generate krudmin_ai:install
bin/rails generate krudmin_ai:docs_sync
```

The installer creates `config/initializers/krudmin_ai.rb`, Importmap pins, an `app/resources/` directory, a managed block in `AGENTS.md`, and the agent-ready package under `docs/krudmin_ai/`. Re-run `docs_sync` whenever the generated host documentation needs to be refreshed; it changes neither application code nor dependencies.

### 3. Configure The Security Providers

Before enabling any resource, replace all five placeholders in `config/initializers/krudmin_ai.rb` with named host provider objects:

```ruby
KrudminAI.configure do |config|
	config.authentication_provider = HostAuthenticationProvider.new
	config.tenant_provider = HostTenantProvider.new
	config.authorization_provider = HostAuthorizationProvider.new
	config.audit_provider = HostAuditProvider.new
	config.notification_provider = HostNotificationProvider.new
end
```

The host does not boot protected resources with an absent or malformed provider. Implement authentication from verified session state; resolve the tenant from the authenticated actor; restrict relations in the authorization provider; and make audit persistence durable. The complete interface and security baseline are in [docs/provider_contracts.md](docs/provider_contracts.md).

### 4. Start The Agent-Guided Member Application

For a member-management replacement, read these generated host documents before writing models or routes:

1. `docs/krudmin_ai/coding_agent_workflow.md`
2. `docs/krudmin_ai/member_administration_blueprint.md`
3. `docs/krudmin_ai/member_administration_tasks.md`

They define the tenant/security invariants, member/team/attachment boundary, and the ordered task sequence for coding agents. Start with authentication, tenant resolution, authorization, and audit support; then build members, teams, memberships, notes, and attachments in that order.

### 5. Generate The First Resource

After the host providers and the `Member` model/policy exist, generate the resource scaffold:

```sh
bin/rails generate krudmin_ai:resource Member --fields display_name:string email:email lifecycle:enum joined_on:date
bin/rails db:migrate
```

The generated policy denies access by default. Supply the resource tenant scope, policy scope, tenant-record check, field decisions, and explicit mutation authorization before exposing the routes. Run the generator a second time to confirm managed routes and files remain idempotent.

### 6. Verify The Host Before Building Features

```sh
bin/rails test
bin/rails routes -g members
ruby -rjson -e 'JSON.parse(File.read("docs/krudmin_ai/capability_registry.json"))'
git diff --check
```

At minimum, prove anonymous denial, tenant-separated lists, policy denial, cross-tenant ID rejection, and audit emission before adding teams, rich text, files, imports, dashboards, or AI workflows.

## Resource Example

Resources are plain Ruby classes. Their declarations define model access, query behavior, fields, and mutations in one reviewable place.

```ruby
class OrdersResource < KrudminAI::Resources::Base
	model Order
	routes :orders
	tenant_key :tenant_id

	permit :number, :status, :total, :placed_on, :customer_id
	label "order"
	plural_label "orders"

	list :number, :status, :total, :placed_on
	form :number, :status, :total, :placed_on, :customer_id
	show :number, :status, :total, :placed_on, :customer_id

	field :number, :identifier, prefix: "ORD-", padding: 6
	field :status, :enum, values: %w[draft submitted fulfilled]
	field :total, :currency, unit: "$"
	field :placed_on, :date
	field :customer_id, :remote_belongs_to,
		resource: CustomersResource,
		association: :customer,
		label: :name,
		label_read: ->(_record, _context) { true }

	tenant_scope { |relation, context| relation.where(tenant_id: context.tenant) }
	policy_scope { |relation, context| OrderPolicy::Scope.new(context.actor, relation).resolve }
	tenant_record { |record, context| record.tenant_id == context.tenant }

	authorize_field :number, read: ->(_record, _context) { true }, write: ->(_record, _context) { true }
	authorize_field :status, read: ->(_record, _context) { true }, write: ->(_record, _context) { true }
	authorize_field :total, read: ->(_record, _context) { true }, write: ->(_record, _context) { true }
	authorize_field :placed_on, read: ->(_record, _context) { true }, write: ->(_record, _context) { true }
	authorize_field :customer_id, read: ->(_record, _context) { true }, write: ->(_record, _context) { true }

	filter_field :status
	sortable :number, :placed_on
	default_sort_by :placed_on, direction: :desc
	paginate per_page: 25, max_per_page: 100

	authorize(:create) { |record, context| OrderPolicy.new(context.actor, record).create? }
	authorize(:update) { |record, context| OrderPolicy.new(context.actor, record).update? }
	authorize(:destroy) { |record, context| OrderPolicy.new(context.actor, record).destroy? }
end
```

The corresponding host controller stays intentionally thin:

```ruby
class OrdersController < KrudminAI::ResourceController
	resource OrdersResource
end
```

Read [docs/resource_query_pipeline.md](docs/resource_query_pipeline.md) before adapting the example. The ordering of tenant scope and policy scope is a security invariant.

## Demo Companion

This repository includes a local Rails companion app under [demo](demo). It demonstrates real tenant-scoped resources, protected mutations, audit records, dashboards, nested relationships, remote lookup, rich text, uploads, and a read-only local assistant.

```sh
cd demo
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/rails server
```

Open `http://localhost:3000/session/new`, choose a seeded account, and visit the Assets workspace. The [demo showcase guide](docs/demo_showcase.md) maps each operations resource to the capabilities it exercises.

## Generators

```sh
bin/rails generate krudmin_ai:install
bin/rails generate krudmin_ai:resource Order
bin/rails generate krudmin_ai:action ApprovePayment --resource Order
bin/rails generate krudmin_ai:dashboard Operations --resource Order
bin/rails generate krudmin_ai:showcase --mode full
bin/rails generate krudmin_ai:docs_sync
```

Generators are idempotent and preserve host-authored code outside their managed markers. Generated resource and action policies are intentionally deny-by-default. Details and generated-host validation steps are in [docs/generators.md](docs/generators.md).

## Design Principles

1. **Authentication is required.** Admin routes do not become public through missing configuration.
2. **Tenant scope comes before policy scope.** Later query steps cannot widen visibility.
3. **Authorization denies by default.** The same decision governs UI, serialization, and persistence.
4. **AI is read-only by default.** Explicit approval and traceability are prerequisites for any automation that writes.
5. **Documentation and evidence matter.** Capability claims are paired with tests, registry entries, and release criteria.

## Development

Run the engine test suite:

```sh
bundle exec rspec
```

Run the demo browser suite:

```sh
cd demo
bundle exec bin/rails test:system
```

Validate the scoped legacy-compatibility inventory and documentation registry:

```sh
ruby bin/verify_classic_parity
ruby -rjson -e 'JSON.parse(File.read("docs/capability_registry.json")); puts "JSON OK"'
git diff --check
```

## Documentation

- [Architecture](docs/architecture.md)
- [Provider contracts](docs/provider_contracts.md)
- [Query access pipeline](docs/resource_query_pipeline.md)
- [Field adapters](docs/field_adapters.md)
- [Actions and bulk operations](docs/actions_and_bulk_operations.md)
- [Data operations](docs/data_operations.md)
- [Dashboards and audit](docs/dashboards_and_audit.md)
- [AI assistant](docs/ai_assistant.md)
- [Migration from Krudmin](docs/migration.md)
- [Beta readiness checkpoint](docs/beta_readiness_checkpoint.md)

## License

KrudminAI is released under the [MIT License](LICENSE).