require "spec_helper"
require "tmpdir"
require "krudmin_ai/generators/dashboard_contract"

RSpec.describe KrudminAI::Generators::DashboardContract do
  around do |example|
    Dir.mktmpdir do |directory|
      @destination_root = directory
      example.run
    end
  end

  it "creates an inert dashboard declaration and records its enabled module" do
    contract = described_class.new(destination_root: @destination_root, name: "Operations", resource: "Order")

    contract.install
    contract.install

    dashboard = File.read(File.join(@destination_root, "app/dashboards/operations_dashboard.rb"))
    manifest = JSON.parse(File.read(File.join(@destination_root, "docs/krudmin_ai/capability_registry.json")))
    expect(dashboard).to include("OperationsDashboard", "OrdersResource", "visible: ->(_context) { false }")
    expect(manifest.fetch("enabled_modules")).to eq(["dashboards"])
  end
end