require "krudmin_ai/fields/adapter"

module KrudminAI
  module Fields
    class RichText < Adapter
      def form_control(form, writable:, errors:, access_note_id:)
        require_rich_text!
        form.rich_text_area(attribute, disabled: !writable, aria: { invalid: errors.any?, describedby: writable ? nil : access_note_id })
      end

      def list_value(record) = plain_text(value(record))
      alias show_value list_value
      alias export_value list_value
      alias ai_value list_value

      private

      def require_rich_text!
        associations = resource.model_class.rich_text_association_names if resource.model_class.respond_to?(:rich_text_association_names)
        return if Array(associations).map(&:to_sym).include?(attribute)
        return if resource.model_class.respond_to?(:reflect_on_association) && resource.model_class.reflect_on_association("rich_text_#{attribute}")

        raise Resources::ConfigurationError, "Rich text field #{attribute} requires has_rich_text on #{resource.model_class.name}"
      end

      def plain_text(content)
        return if content.nil?

        content.respond_to?(:to_plain_text) ? content.to_plain_text : content.to_s
      end
    end

    class File < Adapter
      def form_control(form, writable:, errors:, access_note_id:)
        require_attachment!
        form.file_field(attribute, disabled: !writable, aria: { invalid: errors.any?, describedby: writable ? nil : access_note_id })
      end

      def list_value(record) = filename(value(record))
      alias show_value list_value
      alias export_value list_value
      alias ai_value list_value

      private

      def require_attachment!
        reflections = resource.model_class.attachment_reflections if resource.model_class.respond_to?(:attachment_reflections)
        return if reflections.respond_to?(:key?) && reflections.key?(attribute.to_s)

        raise Resources::ConfigurationError, "File field #{attribute} requires has_one_attached or has_many_attached on #{resource.model_class.name}"
      end

      def filename(attachment)
        return if attachment.nil?

        attachment.respond_to?(:filename) ? attachment.filename.to_s : attachment.to_s
      end
    end

    class Image < File
    end

    class Computed < Adapter
      def value(record)
        calculator = options.fetch(:value) { raise Resources::ConfigurationError, "Computed field #{attribute} requires a value callable" }
        calculator.call(record)
      end

      def form_control(_form, writable:, errors:, access_note_id:)
        raise Resources::ConfigurationError, "Computed field #{attribute} cannot be writable" if writable

        ""
      end

      def parameter(_value)
        raise ArgumentError, "#{attribute} is computed and cannot be assigned"
      end
    end
  end
end
