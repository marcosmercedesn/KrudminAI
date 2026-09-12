module KrudminAI
  class Engine < ::Rails::Engine
    isolate_namespace KrudminAI

    config.after_initialize do
      KrudminAI.config.validate_providers!
    end

    initializer "krudmin_ai.assets" do |app|
      app.config.assets.paths << root.join("app/javascript")
    end

    config.generators do |generators|
      generators.test_framework :rspec
    end
  end
end