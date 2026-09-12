require "krudmin_ai/version"
require "lucide-rails"
require "krudmin_ai/engine"
require "krudmin_ai/configuration"
require "krudmin_ai/providers"
require "krudmin_ai/navigation_item"
require "krudmin_ai/access_context"
require "krudmin_ai/resources/relationship"
require "krudmin_ai/resources/base"
require "krudmin_ai/icon_helper"
require "krudmin_ai/resource_controller"
require "krudmin_ai/query_access_pipeline"
require "krudmin_ai/ai/context_builder"
require "krudmin_ai/ai/tool_router"
require "krudmin_ai/ai/assistant"
require "krudmin_ai/dashboards/widgets/base"
require "krudmin_ai/dashboards/widgets/count"
require "krudmin_ai/dashboards/widgets/table"
require "krudmin_ai/dashboards/widgets/summary"
require "krudmin_ai/mutation_pipeline"
require "krudmin_ai/mutation_response"
require "krudmin_ai/generators/file_writer"
require "krudmin_ai/generators/install_contract"
require "krudmin_ai/generators/resource_contract"
require "krudmin_ai/generators/showcase_contract"

module KrudminAI
	class << self
		def config
			@config ||= Configuration.new
		end

		def configure
			yield config
		end
	end
end