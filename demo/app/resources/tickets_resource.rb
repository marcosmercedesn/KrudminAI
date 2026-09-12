class TicketsResource < KrudminAI::Resources::Base
  model DemoTicket
  routes :tickets
  icon :ticket
  tenant_key :tenant
  permit :title, :description, :state, :priority, :assignee

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