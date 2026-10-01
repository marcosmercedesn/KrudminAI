module KrudminAI
  module Resources
    class Action
      attr_reader :name, :label, :writes, :icon, :placement, :confirmation, :method, :variant

      def initialize(name:, label:, writes:, handler:, icon: :play, placement: :record, confirmation: nil, method: :post, variant: :default, available_if: nil)
        @name = name.to_sym
        @label = label.to_s
        @writes = writes.map(&:to_sym).uniq.freeze
        @icon = icon.to_sym
        @placement = placement.to_sym
        @confirmation = confirmation
        @method = method.to_sym
        @variant = variant.to_sym
        @handler = handler
        @available_if = available_if
      end

      def call(record, context)
        @handler.call(record, context) == true
      end

      def available?(record, context)
        !@available_if || @available_if.call(record, context) == true
      rescue StandardError
        false
      end
    end
  end
end
