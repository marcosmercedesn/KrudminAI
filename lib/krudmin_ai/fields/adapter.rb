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

      def form_control(form, writable:, errors:, access_note_id:, rules: {}, error_id: nil)
        form.text_field(attribute, **control_options(writable:, errors:, access_note_id:, error_id:, rules:, class_name: "krudmin-ai-input"))
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

      # Type-level constraints this adapter already enforces in parameter/validate_submission.
      def validation_constraints
        {}
      end

      # Adapters without a user-editable control never project client rules.
      def validation_projectable?
        true
      end

      def parameter(value)
        value
      end

      def validate_submission(_record, _value, _context, authorization_provider: nil)
      end

      def blank?(value)
        value.respond_to?(:blank?) ? value.blank? : value.nil? || value == ""
      end

      # Native constraints the rendered control can express. Overridden per control family
      # because minlength/pattern and min/max/step are not interchangeable.
      def native_validation_attributes(rules)
        length_attributes(rules).merge(rules[:pattern] ? { pattern: rules[:pattern] } : {})
      end

      def control_options(writable:, errors:, access_note_id:, class_name:, error_id: nil, rules: {})
        described_by = [ (access_note_id unless writable), error_id ].compact.join(" ")
        native = writable ? native_validation_attributes(rules) : {}
        aria = { invalid: errors.any?, describedby: described_by.empty? ? nil : described_by }
        aria[:required] = true if native[:required]

        { class: class_name, disabled: !writable, aria: }.merge(native)
      end

      def length_attributes(rules)
        attributes = required_attributes(rules)
        attributes[:minlength] = rules[:minimum] || rules[:is] if rules[:minimum] || rules[:is]
        attributes[:maxlength] = rules[:maximum] || rules[:is] if rules[:maximum] || rules[:is]
        attributes
      end

      def required_attributes(rules)
        rules[:required] ? { required: true } : {}
      end
    end
  end
end
