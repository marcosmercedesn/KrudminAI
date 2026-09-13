require "rails/generators"
require "krudmin_ai/generators/resource_contract"

module KrudminAI
  module Generators
    class ResourceGenerator < Rails::Generators::NamedBase
      namespace "krudmin_ai:resource"
      class_option :namespace, type: :string, default: "admin", desc: "Controller namespace"
      class_option :fields, type: :array, default: [], desc: "Typed fields as name:type, for example name:string age:number"
      class_option :associations, type: :array, default: [], desc: "Nested associations as name:has_many:field,field or name:has_one:field"
      class_option :workflows, type: :array, default: [], desc: "Deny-by-default transitions as name:from:to"

      def install_resource
        ResourceContract.new(destination_root:, name:, namespace: options[:namespace], fields: options[:fields], associations: options[:associations], workflows: options[:workflows]).install
      end
    end
  end
end
