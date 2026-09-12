require "rails/generators"
require "krudmin_ai/generators/resource_contract"

module KrudminAI
  module Generators
    class ResourceGenerator < Rails::Generators::NamedBase
      namespace "krudmin_ai:resource"
      class_option :namespace, type: :string, default: "admin", desc: "Controller namespace"

      def install_resource
        ResourceContract.new(destination_root:, name:, namespace: options[:namespace]).install
      end
    end
  end
end