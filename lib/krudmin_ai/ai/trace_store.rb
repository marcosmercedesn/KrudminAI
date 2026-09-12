require "securerandom"

module KrudminAI
  module Ai
    RetainedTrace = Data.define(:id, :actor, :tenant, :prompt_template, :provider, :scoped_context_fingerprint, :output, :action_references, :status, :created_at)

    class InMemoryTraceStore
      def initialize(clock: -> { Time.now }, output_redactor: ->(_output) { "[redacted]" })
        @clock = clock
        @output_redactor = output_redactor
        @traces = []
      end

      def record(trace, tenant:)
        retained_trace = RetainedTrace.new(
          SecureRandom.uuid,
          trace.actor,
          tenant,
          trace.prompt_template,
          trace.provider,
          trace.scoped_context_fingerprint,
          output_redactor.call(trace.output),
          trace.action_references,
          trace.status,
          @clock.call
        )
        traces << retained_trace
        retained_trace
      end

      def recorder_for(context)
        TraceRecorder.new(self, context)
      end

      def search(context:, query: nil, statuses: nil)
        context.validate!
        matches = traces.select { |trace| trace.tenant == context.tenant }
        matches = matches.select { |trace| Array(statuses).map(&:to_sym).include?(trace.status) } if statuses
        return matches if query.to_s.empty?

        normalized_query = query.to_s.downcase
        matches.select do |trace|
          [trace.prompt_template, trace.provider, trace.status].join(" ").downcase.include?(normalized_query)
        end
      end

      def export(context:, statuses: nil)
        search(context:, statuses:).map(&:to_h)
      end

      private

      attr_reader :traces, :output_redactor
    end

    TraceRecorder = Data.define(:store, :context) do
      def record(trace)
        store.record(trace, tenant: context.tenant)
      end
    end
  end
end