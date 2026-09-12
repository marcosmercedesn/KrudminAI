class TicketsResource < KrudminAI::Resources::Base
  model DemoTicket
  routes :tickets
  icon :ticket
  tenant_key :tenant
  permit :title, :description, :state, :priority, :assignee
  label "ticket"
  plural_label "tickets"
  list :title, :state, :priority, :assignee
  form :title, :description, :state, :priority, :assignee
  show :title, :description, :state, :priority, :assignee
  has_many :passengers,
    fields: %i[name position],
    label: "Passengers",
    maximum: 6,
    order: :position,
    authorize: ->(passenger, action, context) {
      ticket = passenger.demo_ticket || DemoTicket.new(tenant: context.tenant, assignee: context.actor.name)
      policy = DemoTicketPolicy.new(context.actor, ticket)
      action == :create ? policy.create? : policy.update?
    },
    tenant_record: ->(passenger, context) { passenger.tenant.blank? || passenger.tenant == context.tenant }

  tenant_scope { |relation, context| relation.where(tenant: context.tenant) }
  policy_scope { |relation, context| DemoTicketPolicy::Scope.new(context.actor, relation).resolve }
  tenant_record { |record, context| record.tenant == context.tenant }
  filter(:state) { |relation, value, _context| value.present? ? relation.where(state: value) : relation }
  filter(:priority) { |relation, value, _context| value.present? ? relation.where(priority: value) : relation }
  sortable :created_at, :state, :priority, :title
  default_sort_by :created_at, direction: :desc
  paginate per_page: 20, max_per_page: 50

  authorize(:create) { |record, context| DemoTicketPolicy.new(context.actor, record).create? }
  authorize(:update) { |record, context| DemoTicketPolicy.new(context.actor, record).update? }
  authorize(:destroy) { |record, context| DemoTicketPolicy.new(context.actor, record).destroy? }

  ai_field :title
  ai_field :state
  ai_field :priority
  ai_field :assignee
end