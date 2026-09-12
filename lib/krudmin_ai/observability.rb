require "active_support"
require "active_support/current_attributes"
require "active_support/notifications"
require "digest"
require "json"
require "securerandom"

module KrudminAI
  module Observability
    EVENT_PREFIX = "krudmin_ai".freeze
    SENSITIVE_KEYS = /actor|audit|authorization|cookie|field|input|output|password|prompt|record|secret|session|tenant|token/i

    class Current < ActiveSupport::CurrentAttributes
      attribute :correlation_id
    end

    class << self
      def with_correlation(correlation_id)
        previous = Current.correlation_id
        Current.correlation_id = correlation_id.to_s.empty? ? SecureRandom.uuid : correlation_id.to_s
        yield
      ensure
        Current.correlation_id = previous
      end

      def correlation_id
        Current.correlation_id ||= SecureRandom.uuid
      end

      def emit(event, attributes = {})
        payload = redact(attributes).merge(event: event.to_s, correlation_id: correlation_id)
        ActiveSupport::Notifications.instrument("#{EVENT_PREFIX}.#{event}", payload)
        logger&.info(JSON.generate(payload))
        metrics_provider&.increment("#{EVENT_PREFIX}.#{event}", tags: metric_tags(payload))
        tracing_provider&.record(event: "#{EVENT_PREFIX}.#{event}", attributes: payload)
        payload
      rescue StandardError
        payload
      end

      private

      def logger
        KrudminAI.config.observability_logger
      end

      def metrics_provider
        KrudminAI.config.metrics_provider
      end

      def tracing_provider
        KrudminAI.config.tracing_provider
      end

      def metric_tags(payload)
        payload.slice(:event, :operation, :outcome, :resource, :status).compact.transform_values(&:to_s)
      end

      def redact(value, key = nil)
        return "[REDACTED:#{Digest::SHA256.hexdigest(value.to_s)[0, 12]}]" if key&.match?(SENSITIVE_KEYS)

        case value
        when Hash
          value.each_with_object({}) { |(child_key, child_value), result| result[child_key] = redact(child_value, child_key.to_s) }
        when Array
          value.map { |item| redact(item) }
        else
          value
        end
      end
    end
  end
end
