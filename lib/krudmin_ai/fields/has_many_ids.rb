require "krudmin_ai/fields/belongs_to"

module KrudminAI
  module Fields
    class HasManyIds < BelongsTo
      def form_control(form, writable:, errors:, access_note_id:, context:, authorization_provider: nil)
        form.collection_select(attribute, options_for(context, authorization_provider:), :last, :first, {}, multiple: true, **control_options(writable:, errors:, access_note_id:, class_name: "krudmin-ai-select"))
      end

      def parameter(value)
        Array(value).reject { |item| blank?(item) }
      end

      def validate_submission(record, submitted_value, context, authorization_provider: nil)
        parameter(submitted_value).each do |identifier|
          super(record, identifier, context, authorization_provider:)
        end
      end
    end
  end
end
