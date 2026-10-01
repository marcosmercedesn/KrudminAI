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
    sortable: :position,
    authorize: ->(passenger, action, context) { PassengerPolicy.new(context.actor, passenger).public_send("#{action}?") },
    tenant_record: ->(passenger, context) { passenger.tenant.blank? || passenger.tenant == context.tenant }
end
```

`fields` is the only child input allowlist. KrudminAI permits `id` and `_destroy` in addition to those fields, and it adds the parent tenant to newly built children before validation. `maximum` limits submitted rows as well as disabling the add control at that count.

### Optional Child Ordering

Set `sortable: :position` on a `has_many` declaration to enable row ordering; omit it to retain the ordinary nested editor. Use a child integer column (for example `position` or `index`) that appears in `fields`, and declare `read` and `write` field authorizers for it. The host model must accept that column through Rails nested attributes. The engine rejects declarations without an editable sorting field and a write handler. The `order:` option remains available for read-only association display; `sortable:` orders the edit form and relationship details by the selected field without requiring a separate `order:` declaration.

When every displayed child permits reading and writing the sorting field, the editor offers drag handles and Move up/Move down buttons. Dragging the handle previews the entire row and marks the insertion edge on the target; the original row remains visible but dimmed until drop or cancellation. The buttons support keyboard and touch interaction. Adding, removing, dragging, or moving a row renumbers **visible** children from 1 in displayed order, including newly built rows. Persisted rows marked for destruction are excluded. The form submits the new values through the same authorized nested-attribute mutation and audit pipeline when the parent is saved; moving a row alone does not write to the database. Other child fields and unsaved edits remain attached to their rows. If any existing child denies access to the sorting field, reorder controls are hidden for the collection, so the UI cannot imply that an unauthorized renumber will persist. Server-side child field-write authorization still rejects crafted submissions.

The field should hold comparable integer positions; hosts with unique position constraints should account for their database's update order when renumbering multiple children in one save. Ordering is per parent association, not a global ordering across parents. After validation errors the form retains submitted children and sorts them by their submitted positions.

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