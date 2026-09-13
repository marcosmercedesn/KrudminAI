require "rails/generators"
require "krudmin_ai/generators/install_contract"

module KrudminAI
  module Generators
    class DocsSyncGenerator < Rails::Generators::Base
      namespace "krudmin_ai:docs_sync"

      def sync_docs
        InstallContract.new(destination_root:, template_root: KrudminAI::Engine.root.join("templates")).sync_docs
      end
    end
  end
end
