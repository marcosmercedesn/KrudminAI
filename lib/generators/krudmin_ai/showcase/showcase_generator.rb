require "rails/generators"
require "krudmin_ai/generators/showcase_contract"

module KrudminAI
  module Generators
    class ShowcaseGenerator < Rails::Generators::Base
      desc "Install the KrudminAI support-operations showcase"

      def install_showcase
        ShowcaseContract.new(destination_root:, source_root: KrudminAI::Engine.root.join("templates")).install
      end
    end
  end
end