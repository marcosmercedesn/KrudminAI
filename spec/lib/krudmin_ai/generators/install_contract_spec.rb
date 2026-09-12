require "spec_helper"
require "tmpdir"
require "krudmin_ai/generators/install_contract"

RSpec.describe KrudminAI::Generators::InstallContract do
  let(:template_root) { File.expand_path("../../../../templates", __dir__) }
  let(:destination_root) { @destination_root }

  around do |example|
    Dir.mktmpdir do |directory|
      @destination_root = directory
      example.run
    end
  end

  it "installs an initializer, AI instructions, and documentation package", :aggregate_failures do
    described_class.new(destination_root:, template_root:).install

    expect(File.read(File.join(destination_root, "config/initializers/krudmin_ai.rb"))).to include("KrudminAI.configure", "config.navigation_item resource: OrdersResource")
    expect(File.read(File.join(destination_root, "AGENTS.md"))).to include("KRUDMIN_AI_GENERATED_INSTRUCTIONS")
    expect(File).to exist(File.join(destination_root, "docs/krudmin_ai/architecture.md"))
    expect(File).to exist(File.join(destination_root, "docs/krudmin_ai/capability_registry.json"))
  end

  it "syncs only generated documentation and instruction artifacts", :aggregate_failures do
    application_file = File.join(destination_root, "app/models/order.rb")
    FileUtils.mkdir_p(File.dirname(application_file))
    File.write(application_file, "class Order < ApplicationRecord; end\n")

    described_class.new(destination_root:, template_root:).sync_docs

    expect(File.read(application_file)).to eq("class Order < ApplicationRecord; end\n")
    expect(File).not_to exist(File.join(destination_root, "config/initializers/krudmin_ai.rb"))
    expect(File).to exist(File.join(destination_root, "docs/krudmin_ai/README.md"))
  end

  it "replaces generated instructions without duplicating host content" do
    agents_path = File.join(destination_root, "AGENTS.md")
    File.write(agents_path, "  # Host rules\n")
    contract = described_class.new(destination_root:, template_root:)

    contract.sync_docs
    contract.sync_docs

    expect(File.read(agents_path)).to start_with("  # Host rules\n")
    expect(File.read(agents_path).scan("BEGIN KRUDMIN_AI_GENERATED_INSTRUCTIONS").length).to eq(1)
  end
end