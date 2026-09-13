module KrudminAI
  module Fields
    class Adapter
      attr_reader :resource, :attribute, :options

      def initialize(resource:, attribute:, options: {})
        @resource = resource
        @attribute = attribute.to_sym
        @options = options.freeze
      end

      def readable?(record, context)
        resource.field_readable?(attribute, record, context)
      end

      def writable?(record, context)
        resource.field_writable?(attribute, record, context)
      end

      def value(record)
        record.public_send(attribute)
      end

      def form_control(form, writable:, errors:, access_note_id:)
        form.text_field(attribute, disabled: !writable, aria: { invalid: errors.any?, describedby: writable ? nil : access_note_id })
      end

      def list_value(record)
        value(record)
      end

      def show_value(record)
        value(record)
      end

      def json_value(record)
        value(record)
      end

      def export_value(record)
        value(record)
      end

      def ai_value(record)
        value(record)
      end

      def serializable?
        true
      end

      def filter_definition
        nil
      end

      def parameter(value)
        value
      end

      def validate_submission(_record, _value, _context, authorization_provider: nil)
      end

      def blank?(value)
        value.respond_to?(:blank?) ? value.blank? : value.nil? || value == ""
      end
    end
  end
end
