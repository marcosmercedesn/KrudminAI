module KrudminAI
  module Resources
    class Relationship
      attr_reader :name, :fields, :label, :maximum, :order, :authorizer, :tenant_record_handler

      def initialize(name:, fields:, label:, maximum:, order:, authorizer:, tenant_record_handler:)
        @name = name.to_sym
        @fields = fields.map(&:to_sym).freeze
        @label = label.to_s
        @maximum = maximum
        @order = order
        @authorizer = authorizer
        @tenant_record_handler = tenant_record_handler
      end

      def parameter
        { "#{name}_attributes": %i[id _destroy] + fields }
      end
    end
  end
end