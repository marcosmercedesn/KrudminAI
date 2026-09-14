module KrudminAI
  module Resources
    class Relationship
      attr_reader :name, :fields, :label, :display_fields, :maximum, :order, :authorizer, :tenant_record_handler, :field_authorizers, :cardinality, :belongs_to_fields, :field_definitions

      def initialize(name:, fields:, label:, display_fields:, maximum:, order:, authorizer:, tenant_record_handler:, field_authorizers:, cardinality: :many, belongs_to_fields: {}, field_definitions: {})
        @name = name.to_sym
        @fields = fields.map(&:to_sym).freeze
        @label = label.to_s
        @display_fields = display_fields.map(&:to_sym).freeze
        @maximum = maximum
        @cardinality = cardinality.to_sym
        raise ArgumentError, "Unsupported relationship cardinality" unless %i[one many].include?(@cardinality)
        @order = order
        @authorizer = authorizer
        @tenant_record_handler = tenant_record_handler
        @field_authorizers = field_authorizers.transform_keys(&:to_sym).transform_values do |decisions|
          { read: decisions[:read], write: decisions[:write] }.freeze
        end.freeze
        @belongs_to_fields = belongs_to_fields.transform_keys(&:to_sym).freeze
        @field_definitions = field_definitions.transform_keys(&:to_sym).freeze
        raise ArgumentError, "Nested belongs-to fields must be declared editable fields" unless @belongs_to_fields.keys.all? { |field| @fields.include?(field) }
      end

      def field_readable?(attribute, record, context)
        authorize_field_decision(attribute, :read, record, context)
      end

      def field_writable?(attribute, record, context)
        authorize_field_decision(attribute, :write, record, context)
      end

      def readable_fields(record, context)
        fields.select { |field| field_readable?(field, record, context) }
      end

      def readable_display_fields(record, context)
        display_fields.select { |field| field_readable?(field, record, context) }
      end

      def parameter
        { "#{name}_attributes": %i[id _destroy] + fields }
      end

      def singular? = cardinality == :one

      def belongs_to_adapter(attribute, resource)
        configuration = belongs_to_fields[attribute.to_sym]
        return unless configuration

        Fields::BelongsTo.new(resource:, attribute:, options: configuration)
      end

      def field_adapter(attribute, resource)
        return belongs_to_adapter(attribute, resource) if belongs_to_fields.key?(attribute.to_sym)

        definition = field_definitions[attribute.to_sym]
        return unless definition

        type = definition.fetch(:type, :string)
        adapter_class = Fields::Registry.send(:adapters).fetch(type.to_sym)
        adapter_class.new(resource:, attribute:, options: definition.fetch(:options, {}))
      end

      # An undeclared nested field still renders a text control, so form rendering and rule
      # projection need an adapter even where field_adapter has nothing declared.
      def form_adapter(attribute, resource)
        field_adapter(attribute, resource) || Fields::String.new(resource:, attribute:, options: {})
      end

      def validation_rules(attribute, record, context, resource)
        Validations::Introspector.call(
          model_class: record.class,
          adapter: form_adapter(attribute, resource),
          attribute:, record:, context:, authorizer: self
        )
      end

      private

      def authorize_field_decision(attribute, decision, record, context)
        field_authorizers.dig(attribute.to_sym, decision)&.call(record, context) == true
      rescue StandardError
        false
      end
    end
  end
end
