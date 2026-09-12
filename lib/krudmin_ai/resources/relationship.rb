module KrudminAI
  module Resources
    class Relationship
      attr_reader :name, :fields, :label, :display_fields, :maximum, :order, :authorizer, :tenant_record_handler, :field_authorizers

      def initialize(name:, fields:, label:, display_fields:, maximum:, order:, authorizer:, tenant_record_handler:, field_authorizers:)
        @name = name.to_sym
        @fields = fields.map(&:to_sym).freeze
        @label = label.to_s
        @display_fields = display_fields.map(&:to_sym).freeze
        @maximum = maximum
        @order = order
        @authorizer = authorizer
        @tenant_record_handler = tenant_record_handler
        @field_authorizers = field_authorizers.transform_keys(&:to_sym).transform_values do |decisions|
          { read: decisions[:read], write: decisions[:write] }.freeze
        end.freeze
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

      private

      def authorize_field_decision(attribute, decision, record, context)
        field_authorizers.dig(attribute.to_sym, decision)&.call(record, context) == true
      rescue StandardError
        false
      end

    end
  end
end