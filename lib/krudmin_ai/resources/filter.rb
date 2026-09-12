module KrudminAI
  module Resources
    class Filter
      TYPES = %i[text select date_range].freeze
      DEFAULT_OPERATORS = {
        text: %i[contains equals starts_with ends_with],
        select: %i[equals],
        date_range: %i[between]
      }.freeze

      attr_reader :name, :type, :label, :operators, :options, :handler

      def initialize(name:, type:, label:, operators:, options:, handler:)
        @name = name.to_sym
        @type = type.to_sym
        raise ArgumentError, "Unsupported filter type" unless TYPES.include?(@type)

        @label = label.to_s
        @operators = Array(operators || DEFAULT_OPERATORS.fetch(@type)).map(&:to_sym).freeze
        raise ArgumentError, "At least one filter operator is required" if @operators.empty?

        @options = options
        @handler = handler
      end

      def operator?(value)
        operators.include?(value.to_sym)
      rescue NoMethodError
        false
      end
    end
  end
end