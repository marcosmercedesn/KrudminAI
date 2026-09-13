require "rails/generators"
require "krudmin_ai/generators/showcase_contract"

module KrudminAI
  module Generators
    class ShowcaseGenerator < Rails::Generators::Base
      namespace "krudmin_ai:showcase"
      desc "Install the KrudminAI support-operations showcase"
      class_option :mode, type: :string, default: "full", enum: %w[lightweight full], desc: "Showcase capability level"

      def install_showcase
        ShowcaseContract.new(destination_root:, source_root: KrudminAI::Engine.root.join("templates"), mode: options[:mode]).install
      end
    end
  end
end
