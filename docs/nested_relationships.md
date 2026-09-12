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

Current support is one direct `has_many` level. `has_one`, nested `belongs_to`, polymorphic relationships, remote association search, and arbitrary-depth nesting are not yet supported.