require "krudmin_ai/observability"

module KrudminAI
  module Fields
    RevealAuditEvent = Data.define(:operation, :actor, :tenant, :roles, :record_id, :field)
    RevealResult = Data.define(:outcome, :value) do
      def success? = outcome == :success
    end

    class Reveal
      def initialize(resource:, context:, auditor:)
        @resource = resource
        @context = context
        @auditor = auditor
      end

      def call(record:, field:)
        adapter = resource.field_adapter(field)
        raise AuthorizationDenied unless adapter.is_a?(Masked)
        raise AuthorizationDenied unless adapter.readable?(record, context) && adapter.revealable?(record, context)
        raise AuditFailure unless auditor.respond_to?(:record)

        auditor.record(RevealAuditEvent.new(:reveal, context.actor, context.tenant, context.roles, record.id, field.to_sym))
        Observability.emit("field.revealed", resource: resource.name, field: field.to_sym)
        RevealResult.new(:success, adapter.value(record))
      rescue AuthenticationRequired, TenantRequired, AuthorizationDenied
        RevealResult.new(:forbidden, nil)
      rescue StandardError
        RevealResult.new(:audit_failed, nil)
      end

      private

      attr_reader :resource, :context, :auditor
    end
  end
end
