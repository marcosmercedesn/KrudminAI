module KrudminAI
  module DataOperations
    class ActiveRecordOperationStore
      TERMINAL_STATUSES = %w[completed failed cancelled].freeze

      def initialize(model:)
        @model = model
      end

      def claim(tenant:, idempotency_key:, kind:, payload: {})
        raise ArgumentError, "An idempotency key is required" if idempotency_key.to_s.empty?

        model.create_or_find_by!(tenant: tenant.to_s, idempotency_key: idempotency_key.to_s, kind: kind.to_s) do |operation|
          operation.status = "queued"
          operation.payload = payload
          operation.progress = 0
        end
      end

      def start(operation)
        transition(operation, from: %w[queued retrying], to: "running")
      end

      def progress(operation, value)
        raise ArgumentError, "Progress must be between 0 and 100" unless value.to_i.between?(0, 100)

        operation.update!(progress: value.to_i) unless terminal?(operation)
        operation
      end

      def complete(operation, result: {})
        transition(operation, from: %w[running], to: "completed", result:)
      end

      def fail(operation, error:)
        transition(operation, from: %w[queued retrying running], to: "failed", error: error.to_s)
      end

      def retry(operation)
        transition(operation, from: %w[failed], to: "retrying", error: nil)
      end

      def cancel(operation)
        transition(operation, from: %w[queued retrying running], to: "cancelled")
      end

      def find(tenant:, idempotency_key:, kind:)
        model.find_by(tenant: tenant.to_s, idempotency_key: idempotency_key.to_s, kind: kind.to_s)
      end

      private

      attr_reader :model

      def model
        @model.respond_to?(:call) ? @model.call : @model
      end

      def transition(operation, from:, to:, **attributes)
        return operation unless from.include?(operation.status)

        operation.update!(attributes.merge(status: to))
        operation
      end

      def terminal?(operation)
        TERMINAL_STATUSES.include?(operation.status)
      end
    end
  end
end
