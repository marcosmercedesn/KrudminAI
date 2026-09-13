# Migrating From Krudmin

KrudminAI is not a drop-in replacement for Krudmin. It intentionally replaces legacy field constants, jQuery presentation hooks, and implicit authorization with resource-owned Rails 8 metadata and fail-closed provider contracts. Start each migration with the static audit:

```sh
ruby bin/krudmin_ai_migrate path/to/app/resource_managers/cars_resource_manager.rb
```

Exit status `0` means the source uses only concepts that have an identified manual KrudminAI mapping. Exit status `2` means the report contains blockers and migration must stop for an explicit design decision. The command never edits host code.

## Constant Mapping

| Legacy Krudmin constant | KrudminAI target | Migration action |
| --- | --- | --- |
| `MODEL_CLASSNAME` | `model Car` | Set the real model class. |
| `RESOURCE_LABEL` / `RESOURCES_LABEL` | `label` / `plural_label` | Copy labels deliberately. |
| `LISTABLE_ATTRIBUTES` | `list` | Retain only permitted, readable fields. |
| `EDITABLE_ATTRIBUTES` | `form` | Retain only permitted, writable scalar fields and declared relationships. |
| `DISPLAYABLE_ATTRIBUTES` | `show` | Retain only readable fields. |
| `SEARCHABLE_ATTRIBUTES` | `filter` blocks | Create an explicit allowlisted filter per supported search input. |
| `LISTABLE_INCLUDES` | `preload` or `includes` | Select only relationships required by the render path. |
| `ORDER_BY` | `sortable` and `default_sort_by` | Declare accepted sort fields and direction. |
| `DASHBOARD_SCOPES` / `DASHBOARD_COLUMNS` | `Dashboards::Base` widgets | Rebuild with scoped relation factories and readable columns. |
| `ATTRIBUTE_TYPES` | resource fields and host presentation | Review each adapter; no type constant is copied automatically. |
| `PRESENTATION_METADATA` | host layout or engine components | Redesign sections; CSS class passthrough is not supported. |

`LISTABLE_ACTIONS` maps only after the target resource has explicit `authorize` declarations and actions/transitions. `RESOURCE_INSTANCE_LABEL_ATTRIBUTE` needs a host presentation choice. The audit reports both cases as warnings because they are not safe automatic rewrites. Its JSON `classifications` identify each recognized item as `automatic`, `assisted`, `manual`, or `blocked`; a blocked item returns exit status `2` and must be redesigned before migration continues.

## Car And Passenger Recipe

Use the resource generator as the secure starting point:

```sh
rails generate krudmin_ai:resource Car
```

Then replace its empty `permit` list, scopes, policy stub, and field decisions before exposing routes. A direct legacy `:HasMany` Passenger relation becomes an explicit relationship declaration, plus the Rails model prerequisite:

```ruby
class Car < ApplicationRecord
  has_many :passengers
  accepts_nested_attributes_for :passengers, allow_destroy: true
end

class CarsResource < KrudminAI::Resources::Base
  model Car
  tenant_key :tenant
  permit :model, :year, :active
  form :model, :year, :active, :passengers
  has_many :passengers,
    fields: %i[name position],
    maximum: 6,
    tenant_record: ->(passenger, context) { passenger.tenant == context.tenant },
    authorize: ->(passenger, action, context) { PassengerPolicy.new(context.actor, passenger).public_send("#{action}?") }
end
```

Add child field read/write predicates, parent `tenant_scope`, `policy_scope`, `tenant_record`, declared actions, and audit provider bindings before running the generated request test. A legacy manager containing `:HasOne`, `:BelongsToOne`, `:StateMachine`, `INLINE_EDITABLE_ATTRIBUTES`, or `BULK_ACTIONS` must not be converted automatically. Direct `:HasMany` and `:HasOne` receive assisted relationship mappings; `:BelongsToOne` and `:StateMachine` are blocked. Inline editing and bulk actions require explicit authorization and audit review. Redesign blocked behavior with an owner and tests before continuing.

## Migration Checklist

For a supported Car/Passenger slice, the intended under-30-minute path is: run the audit; generate the resource; declare model nesting and direct `has_many`; set tenant/policy/field predicates; migrate one list/form/show view to engine defaults; then run the checks below. Stop at any audit blocker.

```sh
ruby bin/krudmin_ai_migrate app/resource_managers/cars_resource_manager.rb
bin/rails db:migrate
bin/rails test test/integration/admin/cars_test.rb
bin/rails routes -g admin_cars
ruby -rjson -e 'JSON.parse(File.read("docs/krudmin_ai/capability_registry.json"))'
```

Before removing Krudmin, test anonymous denial, tenant-separated lists, cross-tenant record lookup, role-gated create/update/destroy, child validation retention, child-ID forgery rejection, and audit emission. Preserve the old manager until those checks pass in the host.

## Deprecations And Shims

No compatibility shim is provided for legacy constants or jQuery APIs. The audit emits actionable warnings for manual translations and blockers for unsupported functionality. A future shim must name the replacement, emit a runtime deprecation warning, remain for at least one minor release, and include a removal version. Security fixes may remove an API earlier only with release notes that identify affected versions and mitigation.