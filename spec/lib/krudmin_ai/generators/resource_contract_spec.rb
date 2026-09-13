require "spec_helper"
require "tmpdir"
require "krudmin_ai/generators/resource_contract"

RSpec.describe KrudminAI::Generators::ResourceContract do
  let(:destination_root) { @destination_root }

  around do |example|
    Dir.mktmpdir do |directory|
      @destination_root = directory
      example.run
    end
  end

  it "generates an authenticated, tenant-aware, deny-by-default resource", :aggregate_failures do
    described_class.new(destination_root:, name: "Order").install

    resource = File.read(File.join(destination_root, "app/resources/orders_resource.rb"))
    controller = File.read(File.join(destination_root, "app/controllers/admin/orders_controller.rb"))
    policy = File.read(File.join(destination_root, "app/policies/order_policy.rb"))
    routes = File.read(File.join(destination_root, "config/routes.rb"))

    expect(resource).to include("routes :orders", "icon :file_text", "tenant_key :tenant", "label \"Order\"", "plural_label \"Orders\"", "permit", "tenant_scope", "policy_scope", "tenant_record", "authorize(:create)")
    expect(controller).to include("< KrudminAI::ResourceController", "resource OrdersResource")
    expect(policy).to include("def create? = false", "scope.none")
    expect(routes).to include("namespace :admin", "resources :orders", "exports/:profile", "imports/:profile", "actions/:action_name", "perform_action")
    expect(File).to exist(File.join(destination_root, "test/integration/admin/orders_test.rb"))
  end

  it "does not duplicate generated routes when rerun" do
    FileUtils.mkdir_p(File.join(destination_root, "config"))
    File.write(File.join(destination_root, "config/routes.rb"), "Rails.application.routes.draw do\nend\n")
    contract = described_class.new(destination_root:, name: "Order")

    contract.install
    contract.install

    routes = File.read(File.join(destination_root, "config/routes.rb"))
    expect(routes.scan("resources :orders").length).to eq(1)
    expect(routes).to end_with("# END KRUDMIN_AI_ORDERS_ROUTES\nend\n")
  end

  it "uses Rails inflection for irregular resource names" do
    described_class.new(destination_root:, name: "Person", namespace: "backoffice").install

    expect(File).to exist(File.join(destination_root, "app/resources/people_resource.rb"))
    expect(File.read(File.join(destination_root, "config/routes.rb"))).to include("resources :people")
    expect(File.read(File.join(destination_root, "app/controllers/backoffice/people_controller.rb"))).to include("PeopleController")
  end

  it "generates a typed Member-style resource from deterministic field declarations" do
    described_class.new(destination_root:, name: "Member", fields: %w[name:string rank:enum joined_on:date]).install

    resource = File.read(File.join(destination_root, "app/resources/members_resource.rb"))
    expect(resource).to include("permit :name, :rank, :joined_on", "field :name, :string", "field :rank, :enum", "form :name, :rank, :joined_on", "authorize_field :joined_on")
    expect do
      described_class.new(destination_root:, name: "Member", fields: [ "unknown:qr_code" ])
    end.to raise_error(ArgumentError, "Unsupported field type: qr_code")
  end

  it "generates inert nested association and workflow declarations that require host authorization" do
    described_class.new(
      destination_root:,
      name: "Car",
      associations: [ "passengers:has_many:name,seat", "insurance:has_one:provider" ],
      workflows: [ "approve:submitted:approved" ]
    ).install

    resource = File.read(File.join(destination_root, "app/resources/cars_resource.rb"))
    expect(resource).to include(
      "has_many :passengers, fields: [:name, :seat], authorize: ->(_record, _action, _context) { false }",
      "has_one :insurance, fields: [:provider], authorize: ->(_record, _action, _context) { false }",
      "authorize(:approve) { |_record, _context| false }",
      "transition :approve, from: :submitted, to: :approved"
    )
  end
end
