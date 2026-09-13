require "active_support/inflector"

ActiveSupport::Inflector.inflections(:en) do |inflections|
  inflections.acronym "AI"
end

module KrudminAI
  class Engine < ::Rails::Engine
    isolate_namespace KrudminAI
    engine_name "krudmin_ai"

    config.after_initialize do
      KrudminAI.config.validate_providers!
    end

    initializer "krudmin_ai.assets" do |app|
      app.config.assets.paths << root.join("app/javascript") if app.config.respond_to?(:assets)
    end

    config.generators do |generators|
      generators.test_framework :rspec
    end
  end
end
