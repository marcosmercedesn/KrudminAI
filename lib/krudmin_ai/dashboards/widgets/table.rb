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

        def visible_columns(record)
          resource.readable_fields(columns, record, context)
        end

        def records
          paginated_relation(per_page: limit)
        end

        def rows
          records.map do |record|
            visible_columns(record).to_h { |field| [field, record.public_send(field)] }
          end
        end

        private

        attr_reader :limit
      end
    end
  end
end