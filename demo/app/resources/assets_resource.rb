class AssetsResource < KrudminAI::Resources::Base
  model DemoAsset
  routes :assets
  icon :cpu
  tenant_key :tenant
  permit :name, :description, :contact_email, :access_code, :lifecycle, :asset_tag, :serial_number, :purchase_price, :uptime_target, :installed_on, :maintenance_window, :commissioned_at, :active, :configuration, :photo, :manual, :inspection_notes, :demo_location_id, :demo_vendor_id
  %i[name description contact_email access_code lifecycle asset_tag serial_number purchase_price uptime_target installed_on maintenance_window commissioned_at active configuration photo manual inspection_notes demo_location_id demo_vendor_id].each do |attribute|
    authorize_field attribute, read: ->(_record, _context) { true }, write: ->(_record, _context) { true }
  end
  authorize_field :service_score, read: ->(_record, _context) { true }, write: ->(_record, _context) { false }
  label "asset"
  plural_label "assets"
  list :name, :asset_tag, :lifecycle, :demo_location_id, :demo_vendor_id, :service_score
  form :name, :description, :contact_email, :access_code, :lifecycle, :asset_tag, :serial_number, :purchase_price, :uptime_target, :installed_on, :maintenance_window, :commissioned_at, :active, :configuration, :photo, :manual, :inspection_notes, :demo_location_id, :demo_vendor_id, :service_score
  show :name, :description, :contact_email, :lifecycle, :asset_tag, :serial_number, :purchase_price, :uptime_target, :installed_on, :maintenance_window, :commissioned_at, :active, :configuration, :photo, :manual, :inspection_notes, :demo_location_id, :demo_vendor_id, :service_score
  section :identity, label: "Asset identity", fields: %i[name asset_tag lifecycle active], columns: :two
  section :assignment, label: "Assignment", fields: %i[demo_location_id demo_vendor_id contact_email], columns: :two
  section :operations, label: "Operational profile", fields: %i[installed_on maintenance_window commissioned_at purchase_price uptime_target service_score], columns: :two
  section :documentation, label: "Documentation", fields: %i[description configuration inspection_notes photo manual], columns: :one
  field :description, :text
  field :contact_email, :email
  field :access_code, :password
  field :lifecycle, :enum, values: DemoAsset::LIFECYCLES
  field :asset_tag, :identifier, prefix: "AST-", padding: 5
  field :serial_number, :masked
  field :purchase_price, :currency, unit: "$"
  field :uptime_target, :percentage
  field :installed_on, :date
  field :maintenance_window, :time
  field :commissioned_at, :datetime
  field :active, :boolean
  field :configuration, :json
  field :photo, :image
  field :manual, :file
  field :inspection_notes, :rich_text
  field :demo_location_id, :belongs_to, association: :demo_location, resource: LocationsResource, label: :name, label_read: ->(_record, _context) { true }
  field :demo_vendor_id, :remote_belongs_to, association: :demo_vendor, resource: VendorsResource, label: :name, label_read: ->(_record, _context) { true }, minimum_query_length: 2
  field :service_score, :computed, value: ->(asset) { "#{asset.service_score}/100" }
  has_one :profile,
    fields: %i[network_address rack_position power_source],
    label: "Deployment profile",
    authorize: ->(profile, action, context) { policy = DemoOperationsPolicy.new(context.actor, profile.demo_asset || DemoAsset.new(tenant: context.tenant)); action == :create ? policy.create? : policy.update? },
    tenant_record: ->(profile, context) { profile.tenant.blank? || profile.tenant == context.tenant },
    field_authorizers: %i[network_address rack_position power_source].index_with { { read: ->(_record, _context) { true }, write: ->(_record, _context) { true } } }
  has_many :maintenance_tasks,
    fields: %i[title status due_on estimated_minutes],
    label: "Maintenance tasks",
    maximum: 6,
    order: :due_on,
    authorize: ->(task, action, context) { policy = DemoOperationsPolicy.new(context.actor, task.demo_asset || DemoAsset.new(tenant: context.tenant)); action == :create ? policy.create? : policy.update? },
    tenant_record: ->(task, context) { task.tenant.blank? || task.tenant == context.tenant },
    field_authorizers: %i[title status due_on estimated_minutes].index_with { { read: ->(_record, _context) { true }, write: ->(_record, _context) { true } } }
  tenant_scope { |relation, context| relation.where(tenant: context.tenant) }
  policy_scope { |relation, context| DemoOperationsPolicy::Scope.new(context.actor, relation).resolve }
  tenant_record { |record, context| record.tenant == context.tenant }
  filter :name, label: "Asset", operators: %i[contains equals starts_with] do |relation, value, _context, operator|
    operator == :equals ? relation.where(name: value) : relation.where("name LIKE ?", operator == :starts_with ? "#{value}%" : "%#{value}%")
  end
  filter :lifecycle, type: :select, label: "Lifecycle", options: DemoAsset::LIFECYCLES do |relation, value, _context|
    value.present? ? relation.where(lifecycle: value) : relation
  end
  filter :installed_on, type: :date_range, label: "Installed on" do |relation, value, _context|
    value["from"].present? ? relation.where(installed_on: Date.iso8601(value["from"])..) : relation
  end
  preload :demo_location, :demo_vendor, :profile, :maintenance_tasks
  sortable :name, :asset_tag, :lifecycle, :installed_on
  default_sort_by :name
  paginate per_page: 20, max_per_page: 50
  authorize(:create) { |record, context| DemoOperationsPolicy.new(context.actor, record).create? }
  authorize(:update) { |record, context| DemoOperationsPolicy.new(context.actor, record).update? }
  authorize(:destroy) { |record, context| DemoOperationsPolicy.new(context.actor, record).destroy? }
  ai_field :name
  ai_field :lifecycle
  ai_field :service_score
end
