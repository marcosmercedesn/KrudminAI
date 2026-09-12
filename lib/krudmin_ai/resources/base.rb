module KrudminAI
  module Resources
    class ConfigurationError < StandardError; end

    class Base
      class << self
        attr_reader :model_class, :tenant_scope_handler, :policy_scope_handler, :filters,
                    :sortable_attributes, :default_sort, :pagination_options, :tenant_record_handler,
                    :action_authorizers, :ai_context_fields, :permitted_attributes, :tenant_attribute,
                    :route_key, :icon_name, :resource_label, :resources_label, :list_fields,
                    :form_fields, :show_fields, :relationships, :included_associations,
                    :preloaded_associations, :archive_attribute

        def inherited(subclass)
          super
          subclass.instance_variable_set(:@filters, filters.dup)
          subclass.instance_variable_set(:@sortable_attributes, sortable_attributes.dup)
          subclass.instance_variable_set(:@default_sort, default_sort.dup)
          subclass.instance_variable_set(:@pagination_options, pagination_options.dup)
          subclass.instance_variable_set(:@action_authorizers, action_authorizers.dup)
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

        def ai_field(attribute, &block)
          ai_context_fields[attribute.to_sym] = block || ->(record) { record.public_send(attribute) }
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

        def has_many(name, fields:, label: nil, maximum: 25, order: nil, authorize: nil, tenant_record: nil)
          raise ArgumentError, "Nested fields are required" if fields.empty?
          raise ArgumentError, "maximum must be positive" unless maximum.positive?
          raise ArgumentError, "A child authorization handler is required" unless authorize
          raise ArgumentError, "A child tenant record handler is required" unless tenant_record

          relationships[name.to_sym] = Relationship.new(
            name:,
            fields:,
            label: label || name.to_s.humanize,
            maximum:,
            order:,
            authorizer: authorize,
            tenant_record_handler: tenant_record
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

        def filter(name, &block)
          raise ArgumentError, "A filter handler is required" unless block

          filters[name.to_sym] = block
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
      end

      @filters = {}.freeze
      @sortable_attributes = [].freeze
      @default_sort = {}.freeze
      @pagination_options = { per_page: 25, max_per_page: 100 }.freeze
      @action_authorizers = {}.freeze
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
    end
  end
end