module KrudminAI
  module Dashboards
    module Widgets
      class Summary < Base
        def initialize(summarize:, **options)
          raise ArgumentError, "A summary handler is required" unless summarize.respond_to?(:call)

          super(**options)
          @summarize = summarize
        end

        def value
          @summarize.call(authorized_relation)
        end
      end
    end
  end
end