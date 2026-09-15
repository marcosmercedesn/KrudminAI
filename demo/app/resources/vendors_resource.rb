class VendorsResource < KrudminAI::Resources::Base
  model DemoVendor
  routes :vendors
  icon :building_2
  tenant_key :tenant
  permit :name, :service_tier, :support_email, :preferred
  %i[name service_tier support_email preferred].each { |attribute| authorize_field attribute, read: ->(_record, _context) { true }, write: ->(_record, _context) { true } }
  label "vendor"
  plural_label "vendors"
  list :name, :service_tier, :support_email, :preferred
  form :name, :service_tier, :support_email, :preferred
  show :name, :service_tier, :support_email, :preferred
  field :service_tier, :enum, values: DemoVendor::SERVICE_TIERS
  field :support_email, :email
  field :preferred, :boolean
  tenant_scope { |relation, context| relation.where(tenant: context.tenant) }
  policy_scope { |relation, context| DemoOperationsPolicy::Scope.new(context.actor, relation).resolve }
  tenant_record { |record, context| record.tenant == context.tenant }
  filter_field :name, label: "Vendor"
  filter :service_tier, type: :select, label: "Service tier", options: DemoVendor::SERVICE_TIERS do |relation, value, _context|
    value.present? ? relation.where(service_tier: value) : relation
  end
  sortable :name, :service_tier
  default_sort_by :name
  paginate per_page: 20, max_per_page: 50
  authorize(:create) { |record, context| DemoOperationsPolicy.new(context.actor, record).create? }
  authorize(:update) { |record, context| DemoOperationsPolicy.new(context.actor, record).update? }
  authorize(:destroy) { |record, context| DemoOperationsPolicy.new(context.actor, record).destroy? }
end
