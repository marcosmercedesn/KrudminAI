require "krudmin_ai/ai/assistant"

module KrudminAI
  module Ai
    ReviewDraft = Data.define(:attributes, :evidence, :scoped_context_fingerprint, :status) do
      def ready_for_review?
        status == :pending_review
      end
    end

    class ReviewableExtraction
      def initialize(context:, provider:, tracer:)
        @context = context
        @provider = provider
        @tracer = tracer
      end

      def call(resource:, relation:, prompt_template:, fields:, input: {}, params: {})
        context.validate!
        raise TraceSinkRequired unless tracer.respond_to?(:record)

        permitted_fields = fields.map(&:to_sym)
        raise ArgumentError unless (permitted_fields - resource.permitted_attributes).empty?

        scoped_context = ContextBuilder.new(resource:, context:, params:).build(relation)
        request = Request.new(:structured_extraction, prompt_template, input, scoped_context.records, :read_only, nil)
        response = provider.call(request)
        attributes = response.fetch(:attributes).transform_keys(&:to_sym).slice(*permitted_fields)
        evidence = response.fetch(:evidence, {}).transform_keys(&:to_sym).slice(*permitted_fields)
        draft = ReviewDraft.new(attributes, evidence, scoped_context.fingerprint, :pending_review)
        trace(:pending_review, prompt_template, scoped_context.fingerprint, fields: attributes.keys)
        draft
      rescue AuthenticationRequired, TenantRequired, AuthorizationDenied, ScopeViolation
        trace(:forbidden, prompt_template, nil)
        ReviewDraft.new({}, {}, nil, :forbidden)
      rescue StandardError
        trace(:failed, prompt_template, nil)
        ReviewDraft.new({}, {}, nil, :failed)
      end

      private

      attr_reader :context, :provider, :tracer

      def trace(status, prompt_template, fingerprint, fields: [])
        tracer.record(Trace.new(context.actor, prompt_template, "structured-extraction", fingerprint, nil, fields, status))
      rescue StandardError
        nil
      end
    end
  end
end