require "securerandom"

module KrudminAI
  module Ai
    class ActiveRecordTraceStore
      def initialize(model:, output_redactor: ->(_output) { "[redacted]" })
        @model = model
        @output_redactor = output_redactor
      end

      def record(trace, tenant:)
        model.create!(
          identifier: SecureRandom.uuid,
          actor_identifier: actor_identifier(trace.actor),
          tenant: tenant.to_s,
          prompt_template: trace.prompt_template.to_s,
          provider: trace.provider.to_s,
          scoped_context_fingerprint: trace.scoped_context_fingerprint.to_s,
          output: output_redactor.call(trace.output),
          action_references: trace.action_references,
          status: trace.status.to_s
        )
      end

      def recorder_for(context)
        Recorder.new(self, context)
      end

      def search(context:, query: nil, statuses: nil)
        context.validate!
        relation = model.where(tenant: context.tenant.to_s)
        relation = relation.where(status: Array(statuses).map(&:to_s)) if statuses
        return relation.order(created_at: :desc) if query.to_s.empty?

        relation.where(prompt_template: query.to_s).order(created_at: :desc)
      end

      private

      attr_reader :model, :output_redactor

      def actor_identifier(actor)
        actor.respond_to?(:id) ? actor.id.to_s : actor.to_s
      end

      Recorder = Data.define(:store, :context) do
        def record(trace)
          store.record(trace, tenant: context.tenant)
        end
      end
    end
  end
end
