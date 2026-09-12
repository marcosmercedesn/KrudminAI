require "spec_helper"
require "krudmin_ai/navigation_item"
require "krudmin_ai/configuration"
require "krudmin_ai/providers"
require "krudmin_ai/resources/base"

RSpec.describe KrudminAI::Configuration do
  it "registers multiple resource-backed navigation items", :aggregate_failures do
    orders = Class.new(KrudminAI::Resources::Base) { icon :shopping_cart }
    reports = Class.new(KrudminAI::Resources::Base) { icon :chart_no_axes_combined }
    configuration = described_class.new

    configuration.navigation_item(label: "Orders", resource: orders, route: :orders_path)
    configuration.navigation_item(label: "Reports", resource: reports, route: :reports_path)

    expect(configuration.navigation_items.map(&:display_label)).to eq(["Orders", "Reports"])
    expect(configuration.navigation_items.map(&:icon)).to eq([:shopping_cart, :chart_no_axes_combined])
  end

  let(:authentication_provider) { KrudminAI::Providers::TestAdapters::Authentication.new(Object.new) }
  let(:authorization_provider) { KrudminAI::Providers::TestAdapters::Authorization.new }
  let(:tenant_provider) { KrudminAI::Providers::TestAdapters::Tenant.new(Object.new) }
  let(:audit_provider) { KrudminAI::Providers::TestAdapters::Audit.new }
  let(:notification_provider) { KrudminAI::Providers::TestAdapters::Notification.new }

  it "validates every configured provider interface" do
    configuration = described_class.new
    configuration.authentication_provider = authentication_provider
    configuration.authorization_provider = authorization_provider
    configuration.tenant_provider = tenant_provider
    configuration.audit_provider = audit_provider
    configuration.notification_provider = notification_provider

    expect(configuration.validate_providers!).to be(true)
  end

  it "fails closed when a provider is missing" do
    configuration = described_class.new

    expect { configuration.validate_providers! }
      .to raise_error(KrudminAI::ProviderConfigurationError, "authentication_provider must be configured")
  end

  it "rejects malformed implementations for every provider contract" do
    KrudminAI::Providers::CONTRACTS.each_key do |provider_name|
      configuration = described_class.new
      configuration.authentication_provider = authentication_provider
      configuration.authorization_provider = authorization_provider
      configuration.tenant_provider = tenant_provider
      configuration.audit_provider = audit_provider
      configuration.notification_provider = notification_provider
      configuration.public_send("#{provider_name}=", Object.new)

      expect { configuration.validate_providers! }
        .to raise_error(KrudminAI::ProviderConfigurationError, /#{provider_name} must respond to/)
    end
  end
end