require "krudmin_ai/ai/assistant"
require "krudmin_ai/ai/multi_source_context"

module KrudminAI
  module Ai
    AnalysisResult = Data.define(:status, :output, :evidence, :scoped_context_fingerprint, :errors) do
      def success?
        status == :success
      end
    end

    class MultiSourceAnalysis
      TASKS = %i[cross_record_analysis dashboard_narrative].freeze

      def initialize(context:, provider:, provider_name:, tracer:)
        @context = context
        @provider = provider
        @provider_name = provider_name
        @tracer = tracer
      end

      def call(task:, sources:, template:)
        context.validate!
        raise TraceSinkRequired unless tracer.respond_to?(:record)
        raise ArgumentError unless TASKS.include?(task.to_sym)

        prompt_template = template.fetch(:name)
        instructions = template.fetch(:instructions)
        scoped_context = MultiSourceContextBuilder.new(context:).build(sources)
        response = normalize_response(provider.call(Request.new(task.to_sym, prompt_template, { instructions: }, scoped_context.sources, :read_only, nil)))
        ToolRouter.new.validate!(response.tool_calls, mutation_approved: false)
        evidence = Array(response.action_references).freeze
        trace(:success, prompt_template, scoped_context.fingerprint, evidence)
        AnalysisResult.new(:success, response.output, evidence, scoped_context.fingerprint, [])
      rescue AuthenticationRequired, TenantRequired, AuthorizationDenied, ScopeViolation
        failure(:forbidden, "AI context access was denied", prompt_template)
      rescue UnsafeToolCall
        failure(:unsafe_tool_call, "The requested tool call is not permitted", prompt_template)
      rescue StandardError
        failure(:failed, "The AI analysis could not be completed", prompt_template)
      end

      private

      attr_reader :context, :provider, :provider_name, :tracer

      def normalize_response(response)
        return response if response.is_a?(ProviderResponse)

        ProviderResponse.new(response.fetch(:output), response.fetch(:tool_calls, []), response.fetch(:action_references, []))
      end

      def failure(status, detail, prompt_template)
        trace(status, prompt_template, nil, [])
        AnalysisResult.new(status, nil, [], nil, [{ code: status, detail: }])
      end

      def trace(status, prompt_template, fingerprint, references)
        tracer.record(Trace.new(context.actor, prompt_template, provider_name, fingerprint, nil, references, status))
      rescue StandardError
        nil
      end
    end
  end
end