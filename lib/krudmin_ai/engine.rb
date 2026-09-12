module KrudminAI
  class Engine < ::Rails::Engine
    isolate_namespace KrudminAI

    config.generators do |generators|
      generators.test_framework :rspec
    end
  end
end