module KrudminAI
  module Dashboards
    module Widgets
      class Chart < Base
        def initialize(series:, **options)
          raise ArgumentError, "A chart series handler is required" unless series.respond_to?(:call)

          super(**options)
          @series = series
        end

        def value
          Array(@series.call(authorized_relation)).map do |point|
            label = point.fetch(:label) { point.fetch("label") }
            value = point.fetch(:value) { point.fetch("value") }
            { label: label.to_s, value: value }
          end
        end
      end
    end
  end
end
