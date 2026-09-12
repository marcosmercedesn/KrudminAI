require "krudmin_ai/resources/action"
require "krudmin_ai/resources/filter"
require "krudmin_ai/data_operations/profile"

module KrudminAI
  module Resources
    class ConfigurationError < StandardError; end

    class Base
      class << self
        attr_reader :model_class, :tenant_scope_handler, :policy_scope_handler, :filters,
                    :sortable_attributes, :default_sort, :pagination_options, :tenant_record_handler,
                    :action_authorizers, :ai_context_fields, :permitted_attributes, :tenant_attribute, :filter_definitions,
                    :route_key, :icon_name, :resource_label, :resources_label, :list_fields,
                    :form_fields, :show_fields, :relationships, :included_associations,
                    :preloaded_associations, :archive_attribute, :field_authorizers, :resource_actions,
                    :export_profiles, :import_profiles

        def inherited(subclass)
          super
          subclass.instance_variable_set(:@filters, filters.dup)
          subclass.instance_variable_set(:@filter_definitions, filter_definitions.dup)
          subclass.instance_variable_set(:@sortable_attributes, sortable_attributes.dup)
          subclass.instance_variable_set(:@default_sort, default_sort.dup)
          subclass.instance_variable_set(:@pagination_options, pagination_options.dup)
          subclass.instance_variable_set(:@action_authorizers, action_authorizers.dup)
          subclass.instance_variable_set(:@resource_actions, resource_actions.dup)
          subclass.instance_variable_set(:@field_authorizers, field_authorizers.dup)
          subclass.instance_variable_set(:@tenant_record_handler, tenant_record_handler)
          subclass.instance_variable_set(:@ai_context_fields, ai_context_fields.dup)
          subclass.instance_variable_set(:@permitted_attributes, permitted_attributes.dup)
          subclass.instance_variable_set(:@tenant_attribute, tenant_attribute)
          subclass.instance_variable_set(:@route_key, route_key)
          subclass.instance_variable_set(:@icon_name, icon_name)
          subclass.instance_variable_set(:@resource_label, resource_label)
          subclass.instance_variable_set(:@resources_label, resources_label)
          subclass.instance_variable_set(:@list_fields, list_fields.dup)
          subclass.instance_variable_set(:@form_fields, form_fields.dup)
          subclass.instance_variable_set(:@show_fields, show_fields.dup)
          subclass.instance_variable_set(:@relationships, relationships.dup)
          subclass.instance_variable_set(:@included_associations, included_associations.dup)
          subclass.instance_variable_set(:@preloaded_associations, preloaded_associations.dup)
          subclass.instance_variable_set(:@archive_attribute, archive_attribute)
          subclass.instance_variable_set(:@export_profiles, export_profiles.dup)
          subclass.instance_variable_set(:@import_profiles, import_profiles.dup)
        end

        def model(value = nil)
          return model_class unless value

          @model_class = value
        end

        def tenant_scope(callable = nil, &block)
          @tenant_scope_handler = callable || block
        end

        def policy_scope(callable = nil, &block)
          @policy_scope_handler = callable || block
        end

        def tenant_record(callable = nil, &block)
          @tenant_record_handler = callable || block
        end

        def authorize(action, callable = nil, &block)
          handler = callable || block
          raise ArgumentError, "An authorization handler is required" unless handler

          action_authorizers[action.to_sym] = handler
        end

        def action(name, label: nil, writes: [], &block)
          raise ArgumentError, "An action handler is required" unless block

          normalized_name = name.to_sym
          resource_actions[normalized_name] = Action.new(
            name: normalized_name,
            label: label || normalized_name.to_s.tr("_", " ").capitalize,
            writes:,
            handler: block
          )
        end

        def transition(name, from:, to:, attribute: :state, label: nil)
          allowed_states = Array(from).map(&:to_s).freeze
          target_state = to.to_s
          state_attribute = attribute.to_sym
          raise ArgumentError, "At least one source state is required" if allowed_states.empty?

          action(name, label:, writes: [state_attribute]) do |record, _context|
            if allowed_states.include?(record.public_send(state_attribute).to_s)
              record.public_send("#{state_attribute}=", target_state)
              true
            else
              record.errors.add(state_attribute, "cannot transition from the current state") if record.respond_to?(:errors)
              false
            end
          end
        end

        def action?(name)
          resource_actions.key?(name.to_sym)
        end

        def action_for(name)
          resource_actions[name.to_sym]
        end

        def authorize_field(attribute, read:, write:)
          raise ArgumentError, "A field read authorization handler is required" unless read
          raise ArgumentError, "A field write authorization handler is required" unless write

          field_authorizers[attribute.to_sym] = { read:, write: }.freeze
        end

        def field_readable?(attribute, record, context)
          authorize_field_decision(attribute, :read, record, context)
        end

        def field_writable?(attribute, record, context)
          authorize_field_decision(attribute, :write, record, context)
        end

        def readable_fields(fields, record, context)
          fields.select { |field| field_readable?(field, record, context) }
        end

        def writable_fields(fields, record, context)
          fields.select { |field| field_writable?(field, record, context) }
        end

        def ai_field(attribute, &block)
          ai_context_fields[attribute.to_sym] = block || ->(record) { record.public_send(attribute) }
        end

        def export_profile(name, fields:, masks: {})
          normalized_fields = fields.map(&:to_sym).uniq.freeze
          raise ArgumentError, "Export fields are required" if normalized_fields.empty?
          raise ArgumentError, "Export masks must be callables" unless masks.values.all? { |mask| mask.respond_to?(:call) }

          export_profiles[name.to_sym] = DataOperations::ExportProfile.new(name.to_sym, normalized_fields, masks.transform_keys(&:to_sym).freeze)
        end

        def import_profile(name, mapping:, required: [])
          normalized_mapping = mapping.transform_keys(&:to_s).transform_values(&:to_sym).freeze
          raise ArgumentError, "Import mapping is required" if normalized_mapping.empty?
          raise ArgumentError, "Required import fields must be mapped" unless Array(required).map(&:to_sym).all? { |field| normalized_mapping.value?(field) }

          import_profiles[name.to_sym] = DataOperations::ImportProfile.new(name.to_sym, normalized_mapping, Array(required).map(&:to_sym).uniq.freeze)
        end

        def permit(*attributes)
          @permitted_attributes = attributes.flatten.map(&:to_sym).uniq.freeze
        end

        def label(value = nil)
          return resource_label unless value

          @resource_label = value.to_s
        end

        def plural_label(value = nil)
          return resources_label unless value

          @resources_label = value.to_s
        end

        def list(*attributes)
          return list_fields.empty? ? permitted_attributes : list_fields unless attributes.any?

          @list_fields = attributes.flatten.map(&:to_sym).uniq.freeze
        end

        def form(*attributes)
          return form_fields.empty? ? permitted_attributes : form_fields unless attributes.any?

          @form_fields = attributes.flatten.map(&:to_sym).uniq.freeze
        end

        def show(*attributes)
          return show_fields.empty? ? permitted_attributes : show_fields unless attributes.any?

          @show_fields = attributes.flatten.map(&:to_sym).uniq.freeze
        end

        def includes(*associations)
          return included_associations if associations.empty?

          @included_associations = associations.flatten.map(&:to_sym).uniq.freeze
        end

        def preload(*associations)
          return preloaded_associations if associations.empty?

          @preloaded_associations = associations.flatten.map(&:to_sym).uniq.freeze
        end

        def archive(attribute = :archived_at)
          @archive_attribute = attribute.to_sym
        end

        def archivable?
          !archive_attribute.nil?
        end

        def has_many(name, fields:, label: nil, display: nil, maximum: 25, order: nil, authorize: nil, tenant_record: nil, field_authorizers: {})
          raise ArgumentError, "Nested fields are required" if fields.empty?
          raise ArgumentError, "maximum must be positive" unless maximum.positive?
          raise ArgumentError, "A child authorization handler is required" unless authorize
          raise ArgumentError, "A child tenant record handler is required" unless tenant_record

          relationships[name.to_sym] = Relationship.new(
            name:,
            fields:,
            label: label || name.to_s.humanize,
            display_fields: display || fields,
            maximum:,
            order:,
            authorizer: authorize,
            tenant_record_handler: tenant_record,
            field_authorizers:
          )
        end

        def nested_permitted_attributes
          relationships.values.map(&:parameter)
        end

        def tenant_key(attribute = nil)
          return tenant_attribute unless attribute

          @tenant_attribute = attribute.to_sym
        end

        def routes(key = nil)
          return route_key unless key

          @route_key = key.to_sym
        end

        def icon(value = nil)
          return icon_name unless value

          @icon_name = value.to_sym
        end

        def filter(name, type: :text, label: nil, operators: nil, options: nil, &block)
          raise ArgumentError, "A filter handler is required" unless block

          normalized_name = name.to_sym
          filters[normalized_name] = block
          filter_definitions[normalized_name] = Filter.new(
            name: normalized_name,
            type:,
            label: label || normalized_name.to_s.tr("_", " ").capitalize,
            operators:,
            options:,
            handler: block
          )
        end

        def sortable(*attributes)
          @sortable_attributes = attributes.flatten.map(&:to_sym).uniq.freeze
        end

        def default_sort_by(attribute, direction: :asc)
          @default_sort = { attribute: attribute.to_sym, direction: normalize_direction(direction) }.freeze
        end

        def paginate(per_page: 25, max_per_page: 100)
          raise ArgumentError, "per_page must be positive" unless per_page.positive?
          raise ArgumentError, "max_per_page must be at least per_page" if max_per_page < per_page

          @pagination_options = { per_page: per_page, max_per_page: max_per_page }.freeze
        end

        def authentication_required?
          true
        end

        def validate_query_contract!
          raise ConfigurationError, "Resource model is required" unless model_class
          raise ConfigurationError, "Tenant scope is required" unless tenant_scope_handler
          raise ConfigurationError, "Policy scope is required" unless policy_scope_handler
          raise ConfigurationError, "At least one sortable attribute is required" if sortable_attributes.empty?
          raise ConfigurationError, "Default sort is required" unless default_sort[:attribute]
          raise ConfigurationError, "Default sort must be sortable" unless sortable_attributes.include?(default_sort[:attribute])
        end

        def validate_mutation_contract!(operation)
          raise ConfigurationError, "Resource model is required" unless model_class
          raise ConfigurationError, "Tenant record check is required" unless tenant_record_handler
          raise ConfigurationError, "Archive metadata is required" if %i[archive restore].include?(operation.to_sym) && !archivable?
          raise AuthorizationDenied, "No authorization policy for #{operation}" unless action_authorizers[operation.to_sym]
        end

        def validate_ai_contract!
          validate_query_contract!
          raise ConfigurationError, "At least one AI context field is required" if ai_context_fields.empty?
        end

        private

        def normalize_direction(direction)
          normalized = direction.to_sym
          return normalized if %i[asc desc].include?(normalized)

          raise ArgumentError, "Sort direction must be :asc or :desc"
        end

        def authorize_field_decision(attribute, decision, record, context)
          field_authorizers.dig(attribute.to_sym, decision)&.call(record, context) == true
        rescue StandardError
          false
        end
      end

      @filters = {}.freeze
      @filter_definitions = {}.freeze
      @sortable_attributes = [].freeze
      @default_sort = {}.freeze
      @pagination_options = { per_page: 25, max_per_page: 100 }.freeze
      @action_authorizers = {}.freeze
      @resource_actions = {}.freeze
      @field_authorizers = {}.freeze
      @tenant_record_handler = nil
      @ai_context_fields = {}.freeze
      @permitted_attributes = [].freeze
      @tenant_attribute = :tenant
      @route_key = nil
      @icon_name = :file_text
      @resource_label = nil
      @resources_label = nil
      @list_fields = [].freeze
      @form_fields = [].freeze
      @show_fields = [].freeze
      @relationships = {}.freeze
      @included_associations = [].freeze
      @preloaded_associations = [].freeze
      @archive_attribute = nil
      @export_profiles = {}.freeze
      @import_profiles = {}.freeze
    end
  end
end