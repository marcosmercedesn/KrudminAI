# State Machines

KrudminAI integrates AASM workflows with the same authorization, tenant scope, field policy, transaction, and audit contracts used by every other mutation. State changes are declared by the resource; request parameters never select a model method directly.

## Model

Include AASM and define the machine on the host model:

```ruby
class Order < ApplicationRecord
  include AASM

  aasm column: :status do
    state :draft, initial: true
    state :submitted
    state :approved

    event :submit do
      transitions from: :draft, to: :submitted
    end

    event :approve do
      transitions from: :submitted, to: :approved
      after { self.approved_at = Time.current }
    end
  end
end
```

AASM callbacks run inside KrudminAI's mutation transaction. If persistence or audit recording fails, the state and callback changes roll back together.

## Resource

Declare the field, its write policy, each permitted transition, and action authorization:

```ruby
class OrdersResource < KrudminAI::Resources::Base
  model Order
  permit :number, :total

  field :status, :state_machine,
    colors: { draft: :warning, submitted: :info, approved: :success },
    transition_labels: { submit: "Send for review", approve: "Approve" }

  authorize_field :status,
    read: ->(_record, _context) { true },
    write: ->(_record, context) { context.roles.include?("manager") }

  authorize(:submit) { |record, context| OrderPolicy.new(context.actor, record).submit? }
  authorize(:approve) { |record, context| OrderPolicy.new(context.actor, record).approve? }

  transition :submit, from: :draft, to: :submitted, via: :submit, placement: :both
  transition :approve, from: :submitted, to: :approved, via: :approve, placement: :both
  bulk_action :approve
end
```

Do not add a transition-only state attribute to `permit`. New records receive the machine's initial state. Updates use declared transition actions, and forged state values submitted through ordinary create, update, or inline-edit paths are not accepted. `authorize_field(..., write:)` is still required because the mutation pipeline checks the transition's declared write set.

State-machine fields discover states from the host model by default. Pass `states:` to define labels explicitly, `colors:` for semantic badge variants (`default`, `warning`, `success`, `info`, or `danger`), and `transition_labels:` to label transition actions when their declaration omits `label:`.

Direct assignment is available only as an explicit escape hatch with `allow_direct_write: true`. That option also permits inline editing and should be used only when bypassing transition events and callbacks is intentional.

## Named Machines

Specify the AASM machine and bind the namespaced event and guard methods explicitly:

```ruby
field :review_state, :state_machine, machine: :review
transition :accept,
  attribute: :review_state,
  from: :pending,
  to: :accepted,
  via: :accept_review,
  guard: :may_accept_review?
```

Only statically declared `via:` and `guard:` methods are called. An HTTP `action_name` can resolve only a resource action already registered at boot.

## Generator

After generating the resource, install a deny-by-default workflow scaffold:

```sh
bin/rails generate krudmin_ai:state_machine Order \
  --attribute status \
  --states draft submitted approved \
  --events submit:draft:submitted approve:submitted:approved
```

For a named machine, add `--machine review`. The generator creates a model concern, reload-safe initializer, resource extension, and model test. Generated transition authorizers return `false`; replace each with the host policy before enabling the workflow. Re-running the command does not duplicate the managed resource require.

## Failure Behavior

A transition is unavailable unless the record is in a declared source state and its guard returns true. Member actions return the normal forbidden or invalid mutation response. Bulk actions preflight every selected record before changing any record, preventing a mixed-state selection from partially transitioning. Successful transitions emit the normal audit event with the declared action name.
