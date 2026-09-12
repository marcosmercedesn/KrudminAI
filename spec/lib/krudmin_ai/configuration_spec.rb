require "spec_helper"
require "krudmin_ai/navigation_item"
require "krudmin_ai/configuration"
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

  it "exposes host-provider configuration points" do
    configuration = described_class.new
    configuration.authentication_provider = :host_authentication
    configuration.tenant_provider = :host_tenancy

    expect(configuration).to have_attributes(
      authentication_provider: :host_authentication,
      tenant_provider: :host_tenancy,
      authorization_provider: nil,
      audit_provider: nil
    )
  end
end