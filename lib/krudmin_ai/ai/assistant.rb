require "krudmin_ai/observability"
require "krudmin_ai/ai/context_builder"
require "krudmin_ai/ai/tool_router"

module KrudminAI
  module Ai
    class ApprovalRequired < StandardError; end
    class TraceSinkRequired < StandardError; end

    Request = Data.define(:task, :prompt_template, :input, :context, :mode, :requested_action)
    ProviderResponse = Data.define(:output, :tool_calls, :action_references)
    Trace = Data.define(:actor, :prompt_template, :provider, :scoped_context_fingerprint, :output, :action_references, :status)
    Result = Data.define(:status, :output, :errors, :trace) do
      def success?
        status == :success
      end
    end

    class Assistant
      TASKS = %i[record_summary record_q_and_a document_summary report_insight].freeze

      def initialize(context:, provider:, provider_name:, tracer:, approval_policy: nil)
        @context = context
        @provider = provider
        @provider_name = provider_name
        @tracer = tracer
        @approval_policy = approval_policy
      end

      def call(task:, resource:, relation:, prompt_template:, input: {}, params: {}, requested_action: nil)
        validate_tracer!
        task = validate_task!(task)
        approved = approve_requested_action!(requested_action)
        scoped_context = ContextBuilder.new(resource:, context:, params:).build(relation)
        request = Request.new(task, prompt_template, input, scoped_context.records, requested_action ? :approved_mutation : :read_only, requested_action)
        response = normalize_response(provider.call(request))
        ToolRouter.new.validate!(response.tool_calls, mutation_approved: approved)

        complete(:success, response.output, [], scoped_context, prompt_template, response.action_references)
      rescue AuthenticationRequired, TenantRequired, AuthorizationDenied, ScopeViolation
        complete(:forbidden, nil, [ error(:forbidden, "AI context access was denied") ], nil, prompt_template, [])
      rescue ApprovalRequired
        complete(:approval_required, nil, [ error(:approval_required, "An explicit approval policy is required") ], nil, prompt_template, [])
      rescue UnsafeToolCall
        complete(:unsafe_tool_call, nil, [ error(:unsafe_tool_call, "The requested tool call is not permitted") ], nil, prompt_template, [])
      rescue Resources::ConfigurationError
        complete(:configuration_error, nil, [ error(:configuration_error, "AI context is not configured") ], nil, prompt_template, [])
      rescue ArgumentError
        complete(:invalid_request, nil, [ error(:invalid_request, "Unsupported AI request") ], nil, prompt_template, [])
      rescue StandardError
        complete(:provider_failed, nil, [ error(:provider_failed, "The AI provider is temporarily unavailable") ], nil, prompt_template, [])
      end

      private

      attr_reader :context, :provider, :provider_name, :tracer, :approval_policy

      def validate_tracer!
        raise TraceSinkRequired unless tracer.respond_to?(:record)
      end

      def validate_task!(task)
        normalized = task.to_sym
        raise ArgumentError unless TASKS.include?(normalized)

        normalized
      end

      def approve_requested_action!(requested_action)
        return false unless requested_action
        raise ApprovalRequired unless approval_policy&.call(requested_action, context)

        true
      end

      def normalize_response(response)
        return response if response.is_a?(ProviderResponse)

        ProviderResponse.new(response.fetch(:output), response.fetch(:tool_calls, []), response.fetch(:action_references, []))
      end

      def complete(status, output, errors, scoped_context, prompt_template, action_references)
        trace = Trace.new(context.actor, prompt_template, provider_name, scoped_context&.fingerprint, output, action_references, status)
        tracer.record(trace)
        Observability.emit("ai.completed", outcome: status, provider: provider_name, tenant: context.tenant, prompt_template:, output:, action_references:)
        Result.new(status, output, errors, trace)
      end

      def error(code, detail)
        { code:, detail: }
      end
    end
  end
end
