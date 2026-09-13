require "rails/generators"
require "krudmin_ai/generators/dashboard_contract"

module KrudminAI
  module Generators
    class DashboardGenerator < Rails::Generators::NamedBase
      namespace "krudmin_ai:dashboard"
      class_option :resource, type: :string, required: true, desc: "Resource model name"

      def install_dashboard
        DashboardContract.new(destination_root:, name:, resource: options[:resource]).install
      end
    end
  end
end
