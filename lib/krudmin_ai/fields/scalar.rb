require "bigdecimal"
require "date"
require "json"
require "active_support/time"
require "krudmin_ai/fields/adapter"

module KrudminAI
  module Fields
    class Text < Adapter
      def filter_definition = { type: :text, operators: %i[contains equals starts_with ends_with] }

      def form_control(form, writable:, errors:, access_note_id:, rules: {}, error_id: nil)
        form.text_area(attribute, **control_options(writable:, errors:, access_note_id:, error_id:, rules:, class_name: "krudmin-ai-textarea"))
      end

      # A textarea does not support pattern.
      def native_validation_attributes(rules) = length_attributes(rules)
    end

    class Email < String
      def form_control(form, writable:, errors:, access_note_id:, rules: {}, error_id: nil)
        form.email_field(attribute, **control_options(writable:, errors:, access_note_id:, error_id:, rules:, class_name: "krudmin-ai-input"))
      end

      def validation_constraints = { type: :email }
    end

    class Password < String
      def form_control(form, writable:, errors:, access_note_id:, rules: {}, error_id: nil)
        form.password_field(attribute, **control_options(writable:, errors:, access_note_id:, error_id:, rules:, class_name: "krudmin-ai-input"))
      end

      def list_value(_record) = "[FILTERED]"
      def show_value(_record) = "[FILTERED]"
      def json_value(_record) = nil
      def export_value(_record) = nil
      def ai_value(_record) = nil
      def serializable? = false
      def validation_projectable? = false
    end

    class Hidden < Adapter
      def form_control(form, writable:, errors:, access_note_id:, rules: {}, error_id: nil)
        form.hidden_field(attribute, disabled: !writable, aria: { invalid: errors.any?, describedby: writable ? nil : access_note_id })
      end

      def list_value(_record) = nil
      def show_value(_record) = nil
      def json_value(_record) = nil
      def export_value(_record) = nil
      def ai_value(_record) = nil
      def serializable? = false
      def validation_projectable? = false
    end

    class Number < Adapter
      def filter_definition = { type: :number_range, operators: [ :between ] }

      def form_control(form, writable:, errors:, access_note_id:, rules: {}, error_id: nil)
        form.number_field(attribute, step: options.fetch(:step, 1), **control_options(writable:, errors:, access_note_id:, error_id:, rules:, class_name: "krudmin-ai-input"))
      end

      def parameter(value)
        return nil if blank?(value)

        Integer(value, exception: false) || raise(ArgumentError, "#{attribute} must be a number")
      end

      def validation_constraints = { numeric: true, only_integer: true, step: options.fetch(:step, 1) }

      def native_validation_attributes(rules) = numeric_attributes(rules)

      def list_value(record) = formatted(value(record))
      alias show_value list_value

      def export_value(record) = list_value(record)
      def ai_value(record) = list_value(record)

      private

      def formatted(number)
        return if number.nil?

        number.to_i.to_s.rjust(options.fetch(:padding, 0), "0").prepend(options.fetch(:prefix, "").to_s)
      end

      # HTML min/max are inclusive, so an exclusive bound is left to the rule engine.
      def numeric_attributes(rules)
        attributes = required_attributes(rules)
        minimum = rules[:greater_than_or_equal_to] || rules[:greater_than]
        maximum = rules[:less_than_or_equal_to] || rules[:less_than]
        attributes[:min] = minimum if minimum
        attributes[:max] = maximum if maximum
        attributes[:step] = rules[:step] if rules[:step]
        attributes
      end
    end

    class Decimal < Number
      def form_control(form, writable:, errors:, access_note_id:, rules: {}, error_id: nil)
        form.number_field(attribute, step: options.fetch(:step, "0.01"), **control_options(writable:, errors:, access_note_id:, error_id:, rules:, class_name: "krudmin-ai-input"))
      end

      def parameter(value)
        return nil if blank?(value)

        BigDecimal(value.to_s)
      rescue ArgumentError, TypeError
        raise ArgumentError, "#{attribute} must be a decimal"
      end

      def validation_constraints = { numeric: true, step: options.fetch(:step, "0.01") }

      def list_value(record)
        number = value(record)
        return if number.nil?

        format("%.#{options.fetch(:precision, 2)}f", number)
      end
      alias show_value list_value
    end

    class Currency < Decimal
      def list_value(record)
        number = value(record)
        return if number.nil?

        "#{options.fetch(:unit, "$")}%0.#{options.fetch(:precision, 2)}f" % number
      end
      alias show_value list_value
    end

    class Percentage < Decimal
      def list_value(record)
        number = value(record)
        return if number.nil?

        "#{format("%.#{options.fetch(:precision, 2)}f", number)}%"
      end
      alias show_value list_value
    end

    class Boolean < Adapter
      def filter_definition = { type: :select, options: [ [ "Yes", "true" ], [ "No", "false" ] ] }

      def form_control(form, writable:, errors:, access_note_id:, rules: {}, error_id: nil)
        form.check_box(attribute, **control_options(writable:, errors:, access_note_id:, error_id:, rules:, class_name: "krudmin-ai-checkbox"))
      end

      def native_validation_attributes(rules) = required_attributes(rules)

      def parameter(value)
        return nil if blank?(value)

        return true if [ true, "true", "1", 1 ].include?(value)
        return false if [ false, "false", "0", 0 ].include?(value)

        raise ArgumentError, "#{attribute} must be true or false"
      end
    end

    class Date < Adapter
      def filter_definition = { type: :date_range, operators: [ :between ] }

      def form_control(form, writable:, errors:, access_note_id:, rules: {}, error_id: nil)
        form.date_field(attribute, **control_options(writable:, errors:, access_note_id:, error_id:, rules:, class_name: "krudmin-ai-input"))
      end

      def native_validation_attributes(rules) = required_attributes(rules)

      def parameter(value)
        return nil if blank?(value)

        ::Date.iso8601(value.to_s)
      rescue ArgumentError
        raise ArgumentError, "#{attribute} must be an ISO 8601 date"
      end

      def validation_constraints = { type: :date }
    end

    class Time < Adapter
      def form_control(form, writable:, errors:, access_note_id:, rules: {}, error_id: nil)
        form.time_field(attribute, **control_options(writable:, errors:, access_note_id:, error_id:, rules:, class_name: "krudmin-ai-input"))
      end

      def native_validation_attributes(rules) = required_attributes(rules)

      def parameter(value)
        return nil if blank?(value)

        ::Time.strptime(value.to_s, "%H:%M:%S").strftime("%H:%M:%S")
      rescue ArgumentError
        begin
          ::Time.strptime(value.to_s, "%H:%M").strftime("%H:%M:%S")
        rescue ArgumentError
          raise ArgumentError, "#{attribute} must be an ISO 8601 time"
        end
      end

      def validation_constraints = { type: :time }

      def list_value(record) = formatted(value(record))
      alias show_value list_value

      private

      def formatted(time)
        return if time.nil?

        time.respond_to?(:strftime) ? time.strftime(options.fetch(:format, "%H:%M")) : time.to_s
      end
    end

    class DateTime < Date
      def filter_definition = { type: :datetime_range, operators: [ :between ] }

      def form_control(form, writable:, errors:, access_note_id:, rules: {}, error_id: nil)
        form.datetime_local_field(attribute, **control_options(writable:, errors:, access_note_id:, error_id:, rules:, class_name: "krudmin-ai-input"))
      end

      def parameter(value)
        return nil if blank?(value)

        time_zone = options[:time_zone] || ::Time.zone
        parsed = time_zone.respond_to?(:iso8601) ? time_zone.iso8601(value.to_s) : ::Time.iso8601(value.to_s)
        raise ArgumentError, "#{attribute} must include a valid time" unless parsed

        parsed
      rescue ArgumentError, TypeError
        raise ArgumentError, "#{attribute} must be an ISO 8601 datetime"
      end

      def validation_constraints = { type: :datetime }

      def list_value(record)
        datetime = value(record)
        return if datetime.nil?

        time_zone = options[:time_zone] || ::Time.zone
        datetime = datetime.in_time_zone(time_zone) if time_zone && datetime.respond_to?(:in_time_zone)
        datetime.strftime(options.fetch(:format, "%Y-%m-%d %H:%M"))
      end
      alias show_value list_value
    end

    class Json < Text
      def form_control(form, writable:, errors:, access_note_id:, rules: {}, error_id: nil)
        json = value(form.object)
        form.text_area(
          attribute,
          value: json.nil? ? nil : JSON.generate(json),
          **control_options(writable:, errors:, access_note_id:, error_id:, rules:, class_name: "krudmin-ai-textarea")
        )
      end

      def parameter(value)
        return nil if blank?(value)

        JSON.parse(value.to_s)
      rescue JSON::ParserError
        raise ArgumentError, "#{attribute} must be valid JSON"
      end

      def validation_constraints = { type: :json }

      def list_value(record)
        json = value(record)
        json.nil? ? nil : JSON.generate(json)
      end
      alias show_value list_value
      alias json_value value
      alias export_value list_value
      alias ai_value value
    end

    class Enum < Adapter
      def filter_definition = { type: :select, options: enum_options }

      def form_control(form, writable:, errors:, access_note_id:, rules: {}, error_id: nil)
        select_options = {}
        include_blank_opt = options.fetch(:include_blank, true)
        select_options[:include_blank] = include_blank_opt if include_blank_opt

        form.select(attribute, enum_options, select_options, **control_options(writable:, errors:, access_note_id:, error_id:, rules:, class_name: "krudmin-ai-select"))
      end

      def native_validation_attributes(rules) = required_attributes(rules)

      def parameter(value)
        return nil if blank?(value) && options.fetch(:allow_blank, true)

        candidate = value.to_s
        enum_values.include?(candidate) ? candidate : raise(ArgumentError, "#{attribute} is not an allowed option")
      end

      def validation_constraints
        constraints = { one_of: enum_values }
        constraints[:required] = true unless options.fetch(:allow_blank, true)
        constraints
      end

      private

      def enum_options
        values = options.fetch(:values) { raise Resources::ConfigurationError, "Enum field #{attribute} requires values" }
        values = values.call if values.respond_to?(:call)
        return values.map { |value, label| [ label, value.to_s ] } if values.is_a?(Hash)

        Array(values).map { |value| value.is_a?(Array) ? [ value.last, value.first.to_s ] : value.to_s }
      end

      def enum_values = enum_options.map { |option| option.is_a?(Array) ? option.last : option }
    end

    class Identifier < Number
    end
  end
end
