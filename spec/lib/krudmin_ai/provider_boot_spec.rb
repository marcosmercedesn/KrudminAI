require "spec_helper"
require "open3"
require "rbconfig"

RSpec.describe "provider boot validation" do
  it "stops an unconfigured Rails host before it can serve protected resources" do
    script = <<~RUBY
      $LOAD_PATH.unshift #{File.expand_path("../../../lib", __dir__).inspect}
      require "rails"
      require "action_controller/railtie"
      class Rails::Application::Configuration
        attr_accessor :assets
      end
      require "krudmin_ai"

      class UnconfiguredProviderHost < Rails::Application
        config.assets = Struct.new(:paths).new([])
        config.eager_load = false
        config.secret_key_base = "provider-boot-test"
      end

      UnconfiguredProviderHost.initialize!
    RUBY

    _output, error, status = Open3.capture3(RbConfig.ruby, "-e", script)

    expect(status).not_to be_success
    expect(error).to include("KrudminAI::ProviderConfigurationError", "authentication_provider must be configured")
  end
end