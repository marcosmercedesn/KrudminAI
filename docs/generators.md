# Generators

KrudminAI generators are idempotent. The install generator creates an initializer, `AGENTS.md` managed instructions, a `docs/krudmin_ai/` package, and the resource directory:

```sh
rails generate krudmin_ai:install
```

Use docs-sync to refresh only generated documentation, the capability registry, and the managed instruction block. It never creates or changes application code, routes, dependencies, or initializers:

```sh
rails generate krudmin_ai:install --docs-only
```

The resource generator creates a resource contract, thin generic CRUD controller, deny-by-default policy stub, namespaced routes, and request-spec scaffold:

```sh
rails generate krudmin_ai:resource Order
```

Generated controllers inherit `KrudminAI::ResourceController` and contain only `resource OrdersResource`. The engine controller owns authentication through configured providers, access-context creation, tenant/policy query composition, model loading, create/update/destroy, permitted attributes, and generic `model`, `models`, `resource_path`, `new_resource_path`, `edit_resource_path`, and `collection_path` helpers.

The generated `resources :orders` route is the single Rails registration point. It is idempotently managed by the generator; no CRUD action routes or resource-specific helper calls need to be handwritten. Generated policy methods return `false` and scope resolution returns `scope.none` until the host application supplies explicit authorization rules. Update the resource's tenant scopes, policy scope, tenant record check, action predicates, and `permit` list together.

The generated initializer exposes host-provider placeholders through `KrudminAI.configure`. Authentication, authorization, tenant, and audit providers must be configured before generated resources are enabled.

## Showcase Generator

Install the tenant-separated support-operations blueprint with:

```sh
rails generate krudmin_ai:showcase
```

It creates a ticket model blueprint, secured resource and policy examples, authenticated workflow endpoints, two-tenant seed data, request-spec scaffold, and evaluator/agent walkthroughs. See [showcase_evaluator_walkthrough.md](showcase_evaluator_walkthrough.md) and [showcase_agent_playbook.md](showcase_agent_playbook.md).