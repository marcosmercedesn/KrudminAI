require "rails/generators"
require "krudmin_ai/generators/action_contract"

module KrudminAI
  module Generators
    class ActionGenerator < Rails::Generators::NamedBase
      namespace "krudmin_ai:action"
      class_option :resource, type: :string, required: true, desc: "Resource model name"

      def install_action
        ActionContract.new(destination_root:, name:, resource: options[:resource]).install
      end
    end
  end
end
