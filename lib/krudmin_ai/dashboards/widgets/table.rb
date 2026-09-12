module KrudminAI
  module Dashboards
    module Widgets
      class Table < Base
        def initialize(columns:, limit: 10, **options)
          raise ArgumentError, "columns must not be empty" if columns.empty?
          raise ArgumentError, "limit must be positive" unless limit.positive?

          super(**options)
          @columns = columns.freeze
          @limit = limit
        end

        attr_reader :columns

        def records
          paginated_relation(per_page: limit)
        end

        private

        attr_reader :limit
      end
    end
  end
end