require "digest"
require "json"

module KrudminAI
  module Ai
    ScopedContext = Data.define(:records, :fingerprint)

    class ContextBuilder
      def initialize(resource:, context:, params: {}, max_records: 20)
        raise ArgumentError, "max_records must be positive" unless max_records.positive?

        @resource = resource
        @context = context
        @params = params
        @max_records = max_records
      end

      def build(relation)
        resource.validate_ai_contract!
        scoped_relation = QueryAccessPipeline.new(resource:, context:, params:).authorized_relation(relation)
        records = scoped_relation.limit(max_records).map { |record| serialize(record) }
        ScopedContext.new(records, Digest::SHA256.hexdigest(JSON.generate(records)))
      end

      private

      attr_reader :resource, :context, :params, :max_records

      def serialize(record)
        resource.ai_context_fields.to_h { |field, serializer| [field, serializer.call(record)] }
      end
    end
  end
end