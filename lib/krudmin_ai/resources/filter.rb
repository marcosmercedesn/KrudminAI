require "active_record"

module KrudminAI
  module Resources
    class Filter
      TYPES = %i[text select number_range date_range datetime_range].freeze
      DEFAULT_OPERATORS = {
        text: %i[contains equals starts_with ends_with],
        select: %i[equals],
        number_range: %i[between],
        date_range: %i[between],
        datetime_range: %i[between]
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

      def self.handler_for_field(model_class:, attribute:, type:)
        lambda do |relation, value, _context, operator|
          apply_field_filter(relation, model_class, attribute, type, value, operator)
        end
      end

      def self.apply_field_filter(relation, model_class, attribute, type, value, operator)
        quoted_attribute = model_class.connection.quote_column_name(attribute)

        case type.to_sym
        when :text
          escaped_value = ActiveRecord::Base.sanitize_sql_like(value.to_s)
          predicate = case operator
          when :equals then escaped_value
          when :starts_with then "#{escaped_value}%"
          when :ends_with then "%#{escaped_value}"
          else "%#{escaped_value}%"
          end
          relation.where("LOWER(#{quoted_attribute}) LIKE LOWER(?)", predicate)
        when :select
          relation.where(attribute => value)
        when :number_range, :date_range, :datetime_range
          bounds = value.to_h
          lower = bounds[:from] || bounds["from"]
          upper = bounds[:to] || bounds["to"]
          return relation if lower.blank? && upper.blank?
          return relation.where(attribute => lower..upper) if lower.present? && upper.present?

          lower.present? ? relation.where(attribute => lower..) : relation.where(attribute => ..upper)
        else
          relation
        end
      end
    end
  end
end
