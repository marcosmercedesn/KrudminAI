require "active_record"
require "krudmin_ai/mutation_pipeline"
require "krudmin_ai/query_access_pipeline"

module KrudminAI
  module Ai
    class AutomationTraceRequired < StandardError; end

    AutomationProposal = Data.define(:operation, :record_id, :attributes, :source_fingerprint)
    AutomationTrace = Data.define(:actor, :roles, :tenant, :operation, :record_id, :source_fingerprint, :status)

    class ApprovedAutomation
      def initialize(context:, resource:, relation:, auditor:, tracer:, approval_policy:, authorization_provider: nil)
        @context = context
        @resource = resource
        @relation = relation
        @auditor = auditor
        @tracer = tracer
        @approval_policy = approval_policy
        @authorization_provider = authorization_provider
      end

      def call(proposal:, params: {})
        context.validate!
        raise AutomationTraceRequired unless tracer.respond_to?(:record)
        raise ApprovalRequired unless approval_policy&.call(proposal, context) == true

        trace!(proposal, :approved)
        record = scoped_record(proposal.record_id, params)
        result = MutationPipeline.new(resource:, context:, auditor:, authorization_provider:).call(
          operation: proposal.operation,
          record:,
          attributes: proposal.attributes
        )
        trace(proposal, result.outcome)
        result
      rescue ApprovalRequired
        trace(proposal, :approval_required)
        nil
      rescue AuthenticationRequired, TenantRequired, AuthorizationDenied, ScopeViolation
        trace(proposal, :forbidden)
        nil
      rescue StandardError
        trace(proposal, :failed)
        nil
      end

      private

      attr_reader :context, :resource, :relation, :auditor, :tracer, :approval_policy, :authorization_provider

      def scoped_record(record_id, params)
        QueryAccessPipeline.new(resource:, context:, params:, authorization_provider:).authorized_relation(relation).find(record_id)
      rescue ActiveRecord::RecordNotFound
        raise ScopeViolation, "Record is outside the authorized scope"
      end

      def trace!(proposal, status)
        tracer.record(AutomationTrace.new(context.actor, context.roles, context.tenant, proposal.operation, proposal.record_id, proposal.source_fingerprint, status))
      end

      def trace(proposal, status)
        return unless tracer.respond_to?(:record)

        trace!(proposal, status)
      rescue StandardError
        nil
      end
    end
  end
end