require "spec_helper"
require "tmpdir"
require "krudmin_ai/generators/action_contract"

RSpec.describe KrudminAI::Generators::ActionContract do
  around do |example|
    Dir.mktmpdir do |directory|
      @destination_root = directory
      example.run
    end
  end

  it "adds one deny-by-default managed action declaration to a generated resource" do
    resource_path = File.join(@destination_root, "app/resources/orders_resource.rb")
    FileUtils.mkdir_p(File.dirname(resource_path))
    File.write(resource_path, "class OrdersResource < KrudminAI::Resources::Base\nend\n")
    contract = described_class.new(destination_root: @destination_root, name: "ApprovePayment", resource: "Order")

    contract.install
    contract.install

    resource = File.read(resource_path)
    action = File.read(File.join(@destination_root, "app/resources/orders_resource_actions/approve_payment.rb"))
    expect(resource.scan("BEGIN KRUDMIN_AI_ORDERS_APPROVE_PAYMENT_ACTION_REQUIRE").length).to eq(1)
    expect(action).to include("class OrdersResource", "authorize(:approve_payment)", "action :approve_payment", "label: \"Approve payment\"")
  end
end