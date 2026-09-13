# Nested Relationships

KrudminAI supports engine-rendered `has_many` editors for a resource's direct child association. The host model must use Rails nested attributes with `allow_destroy: true`.

```ruby
class Ticket < ApplicationRecord
  has_many :passengers
  accepts_nested_attributes_for :passengers, allow_destroy: true
end

class TicketsResource < KrudminAI::Resources::Base
  tenant_key :tenant
  has_many :passengers,
    fields: %i[name position],
    label: "Passengers",
    maximum: 6,
    order: :position,
    authorize: ->(passenger, action, context) { PassengerPolicy.new(context.actor, passenger).public_send("#{action}?") },
    tenant_record: ->(passenger, context) { passenger.tenant.blank? || passenger.tenant == context.tenant }
end
```

`fields` is the only child input allowlist. KrudminAI permits `id` and `_destroy` in addition to those fields, and it adds the parent tenant to newly built children before validation. `maximum` limits submitted rows as well as disabling the add control at that count. `order` records the host's ordering field for its own association scope; the current renderer does not reorder child records.

The editor uses a native button, an HTML `template`, and the `krudmin-ai-nested-fields` Stimulus controller. It assigns deterministic numeric per-form client identifiers (`0`, `1`, and so on), which Rails strong parameters accept for nested collections. Removing a persisted row sets `_destroy=1` and hides it; removing a new row removes it from the form. Both controls remain keyboard accessible and require no jQuery.

Before assignment, each supplied existing child ID is looked up through the parent association. A missing ID, a cross-parent ID, a tenant predicate failure, or a child action predicate failure rejects the entire parent mutation. Parent and child saves use the Active Record transaction created by nested attributes. Validation errors retain submitted nested rows and render child field errors. The audit event records current and submitted child IDs under `affected_child_references`.

## Has-One And Nested Belongs-To

Direct `has_one` relationships use the same `fields`, authorization, tenant, and field-authorizer contract as `has_many`, but render one stable nested row and accept one Rails nested-attributes hash. Existing child IDs must resolve to the current parent record; a cross-parent or cross-tenant identifier rejects the whole parent mutation before persistence and audit.

Nested child foreign keys are supported only through an explicit `belongs_to_fields` mapping. Each mapping uses the P4 target-resource contract, so its candidate IDs are tenant-, policy-, provider-, and label-read-scoped before assignment:

```ruby
has_one :insurance,
  fields: %i[provider rank_id],
  # authorize, tenant_record, and field_authorizers omitted
  belongs_to_fields: {
    rank_id: { resource: RanksResource, association: :rank, label: :name, label_read: ->(rank, context) { RankPolicy.new(context.actor, rank).show? } }
  }
```

## Authorized Multi-Select

Use `field :team_ids, :has_many_ids` for direct join-backed associations. It uses the same target resource and `label_read` contract as local belongs-to lookup, validates every submitted ID through its protected relation before Rails assigns it, and rejects an entire crafted set without persistence or audit leakage. Pass the array shape explicitly to `permit`, for example `permit :name, team_ids: []`.

## Explicit Boundaries

P6 supports one direct nested `has_many` or `has_one` level plus explicit nested belongs-to fields. Polymorphic nested relationships and arbitrary-depth nested editors are intentionally unsupported: their target type/path resolution would make tenant, policy, field, and audit decisions ambiguous. Hosts must expose them through separate protected resources until a future capability defines an explicit type allowlist, per-type target resource, and independent evidence.