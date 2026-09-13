require "bigdecimal"
require "date"
require "json"
require "active_support/time"
require "krudmin_ai/fields/adapter"

module KrudminAI
  module Fields
    class Text < Adapter
      def filter_definition = { type: :text, operators: %i[contains equals starts_with ends_with] }

      def form_control(form, writable:, errors:, access_note_id:)
        form.text_area(attribute, disabled: !writable, aria: { invalid: errors.any?, describedby: writable ? nil : access_note_id })
      end
    end

    class Email < String
      def form_control(form, writable:, errors:, access_note_id:)
        form.email_field(attribute, disabled: !writable, aria: { invalid: errors.any?, describedby: writable ? nil : access_note_id })
      end
    end

    class Password < String
      def form_control(form, writable:, errors:, access_note_id:)
        form.password_field(attribute, disabled: !writable, aria: { invalid: errors.any?, describedby: writable ? nil : access_note_id })
      end

      def list_value(_record) = "[FILTERED]"
      def show_value(_record) = "[FILTERED]"
      def json_value(_record) = nil
      def export_value(_record) = nil
      def ai_value(_record) = nil
      def serializable? = false
    end

    class Hidden < Adapter
      def form_control(form, writable:, errors:, access_note_id:)
        form.hidden_field(attribute, disabled: !writable, aria: { invalid: errors.any?, describedby: writable ? nil : access_note_id })
      end

      def list_value(_record) = nil
      def show_value(_record) = nil
      def json_value(_record) = nil
      def export_value(_record) = nil
      def ai_value(_record) = nil
      def serializable? = false
    end

    class Number < Adapter
      def filter_definition = { type: :number_range, operators: [ :between ] }

      def form_control(form, writable:, errors:, access_note_id:)
        form.number_field(attribute, step: options.fetch(:step, 1), disabled: !writable, aria: { invalid: errors.any?, describedby: writable ? nil : access_note_id })
      end

      def parameter(value)
        return nil if blank?(value)

        Integer(value, exception: false) || raise(ArgumentError, "#{attribute} must be a number")
      end

      def list_value(record) = formatted(value(record))
      alias show_value list_value

      def export_value(record) = list_value(record)
      def ai_value(record) = list_value(record)

      private

      def formatted(number)
        return if number.nil?

        number.to_i.to_s.rjust(options.fetch(:padding, 0), "0").prepend(options.fetch(:prefix, "").to_s)
      end
    end

    class Decimal < Number
      def form_control(form, writable:, errors:, access_note_id:)
        form.number_field(attribute, step: options.fetch(:step, "0.01"), disabled: !writable, aria: { invalid: errors.any?, describedby: writable ? nil : access_note_id })
      end

      def parameter(value)
        return nil if blank?(value)

        BigDecimal(value.to_s)
      rescue ArgumentError, TypeError
        raise ArgumentError, "#{attribute} must be a decimal"
      end

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

      def form_control(form, writable:, errors:, access_note_id:)
        form.check_box(attribute, disabled: !writable, aria: { invalid: errors.any?, describedby: writable ? nil : access_note_id })
      end

      def parameter(value)
        return nil if blank?(value)

        return true if [ true, "true", "1", 1 ].include?(value)
        return false if [ false, "false", "0", 0 ].include?(value)

        raise ArgumentError, "#{attribute} must be true or false"
      end
    end

    class Date < Adapter
      def filter_definition = { type: :date_range, operators: [ :between ] }

      def form_control(form, writable:, errors:, access_note_id:)
        form.date_field(attribute, disabled: !writable, aria: { invalid: errors.any?, describedby: writable ? nil : access_note_id })
      end

      def parameter(value)
        return nil if blank?(value)

        ::Date.iso8601(value.to_s)
      rescue ArgumentError
        raise ArgumentError, "#{attribute} must be an ISO 8601 date"
      end
    end

    class Time < Adapter
      def form_control(form, writable:, errors:, access_note_id:)
        form.time_field(attribute, disabled: !writable, aria: { invalid: errors.any?, describedby: writable ? nil : access_note_id })
      end

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

      def form_control(form, writable:, errors:, access_note_id:)
        form.datetime_local_field(attribute, disabled: !writable, aria: { invalid: errors.any?, describedby: writable ? nil : access_note_id })
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
      def parameter(value)
        return nil if blank?(value)

        JSON.parse(value.to_s)
      rescue JSON::ParserError
        raise ArgumentError, "#{attribute} must be valid JSON"
      end

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

      def form_control(form, writable:, errors:, access_note_id:)
        form.select(attribute, enum_options, {}, disabled: !writable, aria: { invalid: errors.any?, describedby: writable ? nil : access_note_id })
      end

      def parameter(value)
        return nil if blank?(value) && options[:allow_blank]

        candidate = value.to_s
        enum_values.include?(candidate) ? candidate : raise(ArgumentError, "#{attribute} is not an allowed option")
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
