module KrudminAI
  module Resources
    class ConfigurationError < StandardError; end

    class Base
      class << self
        attr_reader :model_class, :tenant_scope_handler, :policy_scope_handler, :filters,
                    :sortable_attributes, :default_sort, :pagination_options, :tenant_record_handler,
                    :action_authorizers, :ai_context_fields

        def inherited(subclass)
          super
          subclass.instance_variable_set(:@filters, filters.dup)
          subclass.instance_variable_set(:@sortable_attributes, sortable_attributes.dup)
          subclass.instance_variable_set(:@default_sort, default_sort.dup)
          subclass.instance_variable_set(:@pagination_options, pagination_options.dup)
          subclass.instance_variable_set(:@action_authorizers, action_authorizers.dup)
          subclass.instance_variable_set(:@tenant_record_handler, tenant_record_handler)
          subclass.instance_variable_set(:@ai_context_fields, ai_context_fields.dup)
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
    end
  end
end