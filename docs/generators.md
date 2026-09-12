# Generators

KrudminAI generators are idempotent. The install generator creates an initializer, `AGENTS.md` managed instructions, a `docs/krudmin_ai/` package, and the resource directory:

```sh
rails generate krudmin_ai:install
```

Use docs-sync to refresh only generated documentation, the capability registry, and the managed instruction block. It never creates or changes application code, routes, dependencies, or initializers:

```sh
rails generate krudmin_ai:install --docs-only
```

The resource generator creates a resource contract, authenticated controller, deny-by-default policy stub, namespaced routes, and request-spec scaffold:

```sh
rails generate krudmin_ai:resource Order
```

Generated policy methods return `false` and scope resolution returns `scope.none` until the host application supplies explicit authorization rules. Update the resource's tenant scopes, policy scope, tenant record check, and action predicates together.

The generated initializer exposes host-provider placeholders through `KrudminAI.configure`. Authentication, authorization, tenant, and audit providers must be configured before generated resources are enabled.