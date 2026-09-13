module KrudminAI
  module Ai
    class ActiveRecordProposalStore
      def initialize(model:)
        @model = model
      end

      def create(context:, draft:, operation:, record_id:)
        context.validate!
        model.create!(
          tenant: context.tenant.to_s,
          actor_identifier: actor_identifier(context.actor),
          operation: operation.to_s,
          record_identifier: record_id.to_s,
          attributes: draft.attributes,
          evidence: redact(draft.evidence),
          source_fingerprint: draft.scoped_context_fingerprint,
          status: "pending_review"
        )
      end

      def approve(proposal, context:)
        return proposal unless proposal.tenant == context.tenant.to_s && proposal.status == "pending_review"

        proposal.update!(status: "approved", reviewer_identifier: actor_identifier(context.actor))
        proposal
      end

      def find_approved(context:, identifier:)
        model.find_by(tenant: context.tenant.to_s, id: identifier, status: "approved")
      end

      private

      attr_reader :model

      def actor_identifier(actor)
        actor.respond_to?(:id) ? actor.id.to_s : actor.to_s
      end

      def redact(value)
        value.is_a?(Hash) ? value.transform_values { |item| item.is_a?(Hash) ? redact(item) : "[redacted]" } : "[redacted]"
      end
    end
  end
end
