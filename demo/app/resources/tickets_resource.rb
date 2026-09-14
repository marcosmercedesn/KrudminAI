class TicketsResource < KrudminAI::Resources::Base
  model DemoTicket
  routes :tickets
  icon :ticket
  tenant_key :tenant
  permit :title, :description, :state, :priority, :assignee
  %i[title description state priority assignee].each do |field|
    authorize_field field, read: ->(_record, _context) { true }, write: ->(_record, _context) { true }
  end
  label "ticket"
  plural_label "tickets"
  list :title, :state, :priority, :assignee
  inline_edit :priority
  form :title, :description, :state, :priority, :assignee
  show :title, :description, :state, :priority, :assignee
  preload :passengers
  archive :archived_at
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
    tenant_record: ->(passenger, context) { passenger.tenant.blank? || passenger.tenant == context.tenant },
    field_authorizers: {
      name: { read: ->(_record, _context) { true }, write: ->(_record, _context) { true } },
      position: { read: ->(_record, _context) { true }, write: ->(_record, _context) { true } }
    }

  tenant_scope { |relation, context| relation.where(tenant: context.tenant) }
  policy_scope { |relation, context| DemoTicketPolicy::Scope.new(context.actor, relation).resolve }
  tenant_record { |record, context| record.tenant == context.tenant }
  filter :title, label: "Title", operators: %i[contains equals starts_with] do |relation, value, _context, operator|
    case operator
    when :equals then relation.where(title: value)
    when :starts_with then relation.where("title LIKE ?", "#{value}%")
    else relation.where("title LIKE ?", "%#{value}%")
    end
  end
  filter :state, type: :select, label: "State", options: DemoTicket::STATES do |relation, value, _context|
    value.present? ? relation.where(state: value) : relation
  end
  filter :priority, type: :select, label: "Priority", options: DemoTicket::PRIORITIES do |relation, value, _context|
    value.present? ? relation.where(priority: value) : relation
  end
  sortable :created_at, :state, :priority, :title
  default_sort_by :created_at, direction: :desc
  paginate per_page: 20, max_per_page: 50

  authorize(:create) { |record, context| DemoTicketPolicy.new(context.actor, record).create? }
  authorize(:update) { |record, context| DemoTicketPolicy.new(context.actor, record).update? }
  authorize(:destroy) { |record, context| DemoTicketPolicy.new(context.actor, record).destroy? }
  authorize(:archive) { |record, context| DemoTicketPolicy.new(context.actor, record).destroy? }
  authorize(:restore) { |record, context| DemoTicketPolicy.new(context.actor, record).restore? }
  authorize(:assign_to_me) { |record, context| DemoTicketPolicy.new(context.actor, record).assign_to_me? }
  authorize(:resolve) { |record, context| DemoTicketPolicy.new(context.actor, record).resolve? }

  action :assign_to_me, label: "Assign to me", writes: [ :assignee ] do |record, context|
    record.assignee = context.actor.name
    true
  end
  transition :resolve, from: %i[open assigned], to: :resolved, label: "Resolve"
  bulk_action :resolve

  ai_field :title
  ai_field :state
  ai_field :priority
  ai_field :assignee
end
