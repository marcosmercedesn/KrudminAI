module KrudminAI
  module Resources
    class Action
      attr_reader :name, :label, :writes

      def initialize(name:, label:, writes:, handler:)
        @name = name.to_sym
        @label = label.to_s
        @writes = writes.map(&:to_sym).uniq.freeze
        @handler = handler
      end

      def call(record, context)
        @handler.call(record, context) == true
      end
    end
  end
end