require "rails/generators"
require "krudmin_ai/generators/install_contract"

module KrudminAI
  module Generators
    class InstallGenerator < Rails::Generators::Base
      namespace "krudmin_ai:install"
      class_option :docs_only, type: :boolean, default: false, desc: "Update generated docs and AI instructions only"

      def install_krudmin_ai
        contract = InstallContract.new(destination_root:, template_root: KrudminAI::Engine.root.join("templates"))
        options[:docs_only] ? contract.sync_docs : contract.install
      end
    end
  end
end
