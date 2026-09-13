require "krudmin_ai/fields/adapter"

module KrudminAI
  module Fields
    class BelongsTo < Adapter
      def form_control(form, writable:, errors:, access_note_id:, context:, authorization_provider: nil)
        form.select(attribute, options_for(context, authorization_provider:), { include_blank: options.fetch(:include_blank, true) }, disabled: !writable, aria: { invalid: errors.any?, describedby: writable ? nil : access_note_id })
      end

      def list_value(record, context: nil) = label_for(association_value(record), context)
      alias show_value list_value

      def association_link(record, context)
        candidate = association_value(record)
        return unless candidate && label_readable?(candidate, context)

        link = options[:link]
        link.call(candidate, context) if link
      rescue StandardError
        nil
      end

      def filter_definition = { type: :select, options: ->(context) { options_for(context) } }

      def validate_submission(_record, submitted_value, context, authorization_provider: nil)
        return if blank?(submitted_value) && options.fetch(:include_blank, true)

        candidate = protected_collection(context, authorization_provider:).find(submitted_value)
        raise ScopeViolation unless label_readable?(candidate, context)
      rescue StandardError
        raise ScopeViolation, "Association is outside the authorized collection"
      end

      private

      def protected_collection(context, authorization_provider: nil)
        QueryAccessPipeline.new(
          resource: target_resource,
          context:,
          authorization_provider:
        ).authorized_relation(target_resource.model_class.all)
      end

      def options_for(context, authorization_provider: nil)
        options = []
        protected_collection(context, authorization_provider:).each do |candidate|
          options << [ label_for(candidate, context), candidate.id ] if label_readable?(candidate, context)
        end
        options
      end

      def target_resource
        options.fetch(:resource) { raise Resources::ConfigurationError, "Belongs-to field #{attribute} requires a target resource" }
      end

      def association_value(record)
        record.public_send(options.fetch(:association, attribute.to_s.delete_suffix("_id")))
      end

      def label_for(candidate, context)
        return if candidate.nil?
        return unless label_readable?(candidate, context)

        candidate.public_send(options.fetch(:label, :name))
      end

      def label_readable?(candidate, context)
        options.fetch(:label_read).call(candidate, context) == true
      rescue StandardError
        false
      end
    end
  end
end
