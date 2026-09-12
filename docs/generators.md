# Generators

KrudminAI generators are idempotent. The install generator creates an initializer, `AGENTS.md` managed instructions, a `docs/krudmin_ai/` package, and the resource directory:

```sh
rails generate krudmin_ai:install
```

Use docs-sync to refresh only generated documentation, the capability registry, and the managed instruction block. It never creates or changes application code, routes, dependencies, or initializers:

```sh
rails generate krudmin_ai:docs_sync
```

`rails generate krudmin_ai:install --docs-only` remains an equivalent compatibility command. Both forms update the `KRUDMIN_AI_GENERATED_INSTRUCTIONS` block in `AGENTS.md` and files below `docs/krudmin_ai/`; content outside that marker is retained.

The resource generator creates a resource contract, thin generic CRUD controller, deny-by-default policy stub, namespaced routes, and request-spec scaffold:

```sh
rails generate krudmin_ai:resource Order
```

Rails inflection determines resource filenames and routes, so `Person` generates `PeopleResource` and `resources :people`. Use `--namespace backoffice` to generate a namespaced controller and route block. The generator never replaces an existing generated resource, controller, policy, or test file; it updates only its managed route marker on re-run.

Generated controllers inherit `KrudminAI::ResourceController` and contain only `resource OrdersResource`. The engine controller owns authentication through configured providers, access-context creation, tenant/policy query composition, model loading, create/update/destroy, permitted attributes, engine-owned default index/new/edit/show pages, and generic `model`, `models`, `resource_path`, `new_resource_path`, `edit_resource_path`, and `collection_path` helpers. Generated resources declare singular and plural labels; their list, form, and show fields default to `permit` attributes unless explicitly set with `list`, `form`, or `show`.

The generated `resources :orders` route is the single Rails registration point. It includes the generic `POST /orders/:id/actions/:action_name` member route for declared resource actions and transitions, and is idempotently managed by the generator; no resource-specific controller action is needed. Generated policy methods return `false` and scope resolution returns `scope.none` until the host application supplies explicit authorization rules. Update the resource's tenant scopes, policy scope, tenant record check, action predicates, and `permit` list together. A resource-specific `app/views/orders/*` template overrides the engine default for that action.

The generated initializer exposes host-provider placeholders through `KrudminAI.configure`. Authentication, authorization, tenant, and audit providers must be configured before generated resources are enabled.

## Action Generator

Generate a deny-by-default action declaration with:

```sh
rails generate krudmin_ai:action ApprovePayment --resource Order
```

The command writes an isolated resource extension at `app/resources/orders_resource_actions/approve_payment.rb` and one managed `require_relative` block in `OrdersResource`. The action initially returns `false`; an agent or maintainer must replace it with a resource-owned action implementation, declare field writes, and supply the matching authorization policy before it is available. Re-runs preserve the resource body and do not duplicate the require marker.

## Dashboard Generator

Generate a resource-aware dashboard declaration with:

```sh
rails generate krudmin_ai:dashboard Operations --resource Order
```

The generated dashboard is intentionally inert: its widget visibility predicate is `false` and it has no columns. Configure visibility, fields, filters, and a controller/view integration deliberately. Widget relations must start from the declared resource model and rely on `Dashboards::Base`, so tenant, policy, field, and drill-down controls remain in force.

## Generated Host Manifest

Install and feature generators maintain `docs/krudmin_ai/capability_registry.json`. It records the engine release, enabled modules, feature flags, and provider binding slots. Provider binding values must be identifiers or `null`, never credentials, tokens, or connection strings. Existing host-authored keys and release metadata are retained when the generator updates its own bindings.

## Conformance

Before accepting generated output, run the host migration, generated integration test, route inspection, and registry parse:

```sh
bin/rails db:migrate
bin/rails test test/integration/admin/orders_test.rb
bin/rails routes -g admin_orders
ruby -rjson -e 'JSON.parse(File.read("docs/krudmin_ai/capability_registry.json"))'
```

Run each selected generator a second time and verify that routes and managed markers occur once. Docs-only sync must leave initializer, routes, dependencies, and application source checksums unchanged.

Generator contract checks and the disposable showcase host are generated-companion-fixture evidence. They do not close the independent generated-host beta exit criteria recorded in [beta_release_decision.md](beta_release_decision.md).

## Showcase Generator

Install the tenant-separated support-operations blueprint with:

```sh
rails generate krudmin_ai:showcase --mode full
```

`--mode lightweight` installs only the secured ticket resource, policy, migration, seed data, routes, and walkthroughs. `--mode full` additionally installs the lifecycle dashboard and an executable two-tenant, multi-role Minitest conformance scenario. The full scenario assumes the documented companion host adapter conventions; it is a conformance fixture, not a substitute for a host's authentication, navigation, association, or AI implementation. See [showcase_evaluator_walkthrough.md](showcase_evaluator_walkthrough.md) and [showcase_agent_playbook.md](showcase_agent_playbook.md).