require "spec_helper"
require "tmpdir"
require "krudmin_ai/generators/state_machine_contract"

RSpec.describe KrudminAI::Generators::StateMachineContract do
  around do |example|
    Dir.mktmpdir do |directory|
      @destination_root = directory
      FileUtils.mkdir_p(File.join(directory, "app/resources"))
      File.write(File.join(directory, "app/resources/orders_resource.rb"), "class OrdersResource\nend\n")
      example.run
    end
  end

  it "generates and attaches a deny-by-default AASM workflow" do
    described_class.new(
      destination_root: @destination_root,
      name: "Order",
      states: %w[draft submitted approved],
      events: %w[submit:draft:submitted approve:submitted:approved]
    ).install

    concern = File.read(File.join(@destination_root, "app/models/concerns/order_workflow.rb"))
    extension = File.read(File.join(@destination_root, "app/resources/orders_resource_state_machine.rb"))
    initializer = File.read(File.join(@destination_root, "config/initializers/krudmin_ai_order_workflow.rb"))
    resource = File.read(File.join(@destination_root, "app/resources/orders_resource.rb"))

    expect(concern).to include("include AASM", "aasm column: :status", "event(:submit)", "from: :draft, to: :submitted")
    expect(extension).to include("field :status, :state_machine", "authorize(:submit) { |_record, _context| false }", "via: :submit", "guard: :may_submit?")
    expect(initializer).to include("Order.include(OrderWorkflow) unless Order < OrderWorkflow")
    expect(resource.scan("KRUDMIN_AI_ORDERS_STATE_MACHINE_REQUIRE").length).to eq(2)
    expect(File).to exist(File.join(@destination_root, "test/models/concerns/order_workflow_test.rb"))
  end

  it "uses collision-safe methods for a named machine and remains idempotent" do
    contract = described_class.new(
      destination_root: @destination_root,
      name: "Order",
      machine: "review",
      attribute: "review_state",
      states: %w[pending accepted],
      events: %w[accept:pending:accepted]
    )

    contract.install
    contract.install

    concern = File.read(File.join(@destination_root, "app/models/concerns/order_workflow.rb"))
    extension = File.read(File.join(@destination_root, "app/resources/orders_resource_state_machine.rb"))
    resource = File.read(File.join(@destination_root, "app/resources/orders_resource.rb"))
    expect(concern).to include("aasm(:review, column: :review_state, namespace: :review)")
    expect(extension).to include("machine: :review", "via: :accept_review", "guard: :may_accept_review?")
    expect(resource.scan("require_relative \"orders_resource_state_machine\"").length).to eq(1)
  end

  it "rejects events whose states are not declared" do
    expect do
      described_class.new(destination_root: @destination_root, name: "Order", states: %w[draft], events: %w[submit:draft:submitted])
    end.to raise_error(ArgumentError, "Events reference unknown states: submitted")
  end
end