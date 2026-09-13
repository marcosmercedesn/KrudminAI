require "krudmin_ai/ai/approved_automation"

module KrudminAI
  module Ai
    class DurableProposalExecutor
      def initialize(proposal_store:, automation:)
        @proposal_store = proposal_store
        @automation = automation
      end

      def call(context:, proposal_id:, params: {})
        proposal = proposal_store.find_approved(context:, identifier: proposal_id)
        return nil unless proposal

        automation.call(
          proposal: AutomationProposal.new(
            proposal.operation.to_sym,
            proposal.record_identifier,
            proposal.attributes.transform_keys(&:to_sym),
            proposal.source_fingerprint
          ),
          params:
        )
      end

      private

      attr_reader :proposal_store, :automation
    end
  end
end
