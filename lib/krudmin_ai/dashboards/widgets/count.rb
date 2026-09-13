module KrudminAI
  module Dashboards
    module Widgets
      class Count < Base
        def value
          authorized_relation.count
        end
      end
    end
  end
end
