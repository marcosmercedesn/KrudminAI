module KrudminAI
  module Dashboards
    module Widgets
      class Base
        def initialize(resource:, context:, relation:, params: {})
          @resource = resource
          @context = context
          @relation = relation
          @params = params
        end

        private

        attr_reader :resource, :context, :relation, :params

        def authorized_relation
          @authorized_relation ||= QueryAccessPipeline.new(resource:, context:, params:).authorized_relation(relation)
        end

        def paginated_relation(per_page:)
          @paginated_relation ||= QueryAccessPipeline.new(
            resource:,
            context:,
            params: params.merge(per_page:, page: 1)
          ).call(relation).records
        end
      end
    end
  end
end