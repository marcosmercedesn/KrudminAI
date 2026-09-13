require "digest"
require "json"
require "krudmin_ai/ai/context_builder"

module KrudminAI
  module Ai
    MultiSourceContext = Data.define(:sources, :fingerprint)

    class MultiSourceContextBuilder
      def initialize(context:, params: {}, max_records: 20)
        @context = context
        @params = params
        @max_records = max_records
      end

      def build(sources)
        raise ArgumentError, "At least one source is required" if sources.empty?

        records_by_source = sources.to_h do |name, source|
          resource = source.fetch(:resource)
          relation = source.fetch(:relation)
          [ name.to_sym, ContextBuilder.new(resource:, context:, params:, max_records:).build(relation).records ]
        end
        MultiSourceContext.new(records_by_source, Digest::SHA256.hexdigest(JSON.generate(records_by_source)))
      end

      private

      attr_reader :context, :params, :max_records
    end
  end
end
