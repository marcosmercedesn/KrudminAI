module KrudminAI
  module Ai
    class ProviderUnavailable < StandardError; end

    class ProviderRouter
      def initialize(providers:)
        @providers = providers.transform_keys(&:to_sym).freeze
      end

      def call(request)
        provider_for(request.task).fetch(:client).call(request)
      end

      def provider_name_for(task)
        provider_for(task).fetch(:name)
      end

      private

      attr_reader :providers

      def provider_for(task)
        provider = providers.fetch(task.to_sym)
        return provider if provider.is_a?(Hash) && !provider[:name].to_s.empty? && provider[:client].respond_to?(:call)

        raise ProviderUnavailable, "AI provider is unavailable"
      rescue KeyError
        raise ProviderUnavailable, "AI provider is unavailable"
      end
    end
  end
end