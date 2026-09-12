# Resource Actions And Transitions

Resource actions are declared on the resource and execute through `MutationPipeline`; they require an explicit matching `authorize` predicate. An action declares every resource field it changes so the field write policy is checked before its handler runs.

```ruby
authorize(:assign_to_me) { |record, context| TicketPolicy.new(context.actor, record).assign_to_me? }
action :assign_to_me, label: "Assign to me", writes: [:assignee] do |record, context|
  record.assignee = context.actor.name
  true
end
```

`transition` is a state-column action with a source-state guard. It does not depend on a particular state-machine gem.

```ruby
authorize(:resolve) { |record, context| TicketPolicy.new(context.actor, record).resolve? }
transition :resolve, from: %i[open assigned], to: :resolved, attribute: :state, label: "Resolve"
```

The action handler must return `true` after preparing its mutation. A transition from an invalid state adds a record error, returns the normal invalid response, and emits no audit event. Every action is tenant-checked, resource-policy-checked, provider-checked, field-policy-checked for declared writes, persisted, and audited in the same transaction.

Hosts add the generated member route:

```ruby
resources :tickets do
  post "actions/:action_name", on: :member, to: "tickets#perform_action", as: :action
end
```

The generic show page only renders action controls when the same authorization decision permits the endpoint. Unknown actions and cross-tenant records return `404`; denied actions return the standard accessible `403` HTML, JSON, or Turbo Stream result. Successful HTML actions redirect to the record, JSON returns the standard mutation envelope, and Turbo Stream sets `Turbo-Location` and updates the status region.