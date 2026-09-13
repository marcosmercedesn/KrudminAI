module KrudminAI
  module Audit
    class ActiveRecordStore
      DEFAULT_REDACTED_KEYS = %w[password token secret masked_id].freeze

      def initialize(model:, redacted_keys: DEFAULT_REDACTED_KEYS)
        @model = model
        @redacted_keys = redacted_keys.map(&:to_s).freeze
      end

      def record(event)
        attributes = event.to_h
        model.create!(
          event_type: event.class.name.split("::").last.gsub(/([a-z])([A-Z])/, "\\1_\\2").downcase,
          actor_identifier: actor_identifier(attributes[:actor]),
          tenant: attributes.fetch(:tenant).to_s,
          operation: attributes[:operation].to_s,
          record_type: attributes[:record_type].to_s,
          record_identifier: attributes[:record_id].to_s,
          metadata: attributes.except(:actor, :tenant, :operation, :record_type, :record_id)
        )
      end

      def search(context:, policy_scope: nil, operation: nil, record_type: nil)
        relation = model.where(tenant: context.tenant.to_s)
        relation = policy_scope.call(relation, context) if policy_scope
        relation = relation.where(operation: operation.to_s) if operation
        relation = relation.where(record_type: record_type.to_s) if record_type
        relation.order(created_at: :desc)
      end

      def presentation(event)
        attributes = event.respond_to?(:attributes) ? event.attributes : event.to_h
        attributes.merge("metadata" => redact_metadata(attributes["metadata"] || attributes[:metadata] || {}))
      end

      private

      attr_reader :model, :redacted_keys

      def actor_identifier(actor)
        actor.respond_to?(:id) ? actor.id.to_s : actor.to_s
      end

      def redact_metadata(metadata)
        metadata.to_h.each_with_object({}) do |(key, value), redacted|
          redacted[key.to_s] = if redacted_keys.include?(key.to_s)
                                  "[FILTERED]"
          elsif value.is_a?(Hash)
                                  redact_metadata(value)
          else
                                  value
          end
        end
      end
    end
  end
end
