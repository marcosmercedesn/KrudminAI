class LocationsResource < KrudminAI::Resources::Base
  model DemoLocation
  routes :locations
  icon :map_pin
  tenant_key :tenant
  permit :name, :region, :timezone, :active
  %i[name region timezone active].each { |attribute| authorize_field attribute, read: ->(_record, _context) { true }, write: ->(_record, _context) { true } }
  label "location"
  plural_label "locations"
  list :name, :region, :timezone, :active
  form :name, :region, :timezone, :active
  show :name, :region, :timezone, :active
  field :active, :boolean
  tenant_scope { |relation, context| relation.where(tenant: context.tenant) }
  policy_scope { |relation, context| DemoOperationsPolicy::Scope.new(context.actor, relation).resolve }
  tenant_record { |record, context| record.tenant == context.tenant }
  filter_field :name, label: "Location"
  sortable :name, :region
  default_sort_by :name
  paginate per_page: 20, max_per_page: 50
  authorize(:create) { |record, context| DemoOperationsPolicy.new(context.actor, record).create? }
  authorize(:update) { |record, context| DemoOperationsPolicy.new(context.actor, record).update? }
  authorize(:destroy) { |record, context| DemoOperationsPolicy.new(context.actor, record).destroy? }
end
