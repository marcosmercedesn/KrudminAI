require "spec_helper"
require "tmpdir"
require "krudmin_ai/generators/showcase_contract"

RSpec.describe KrudminAI::Generators::ShowcaseContract do
  let(:source_root) { File.expand_path("../../../../templates", __dir__) }
  let(:destination_root) { @destination_root }

  around do |example|
    Dir.mktmpdir do |directory|
      @destination_root = directory
      example.run
    end
  end

  it "installs tenant-safe support operations examples and walkthroughs", :aggregate_failures do
    described_class.new(destination_root:, source_root:).install

    resource = File.read(File.join(destination_root, "app/resources/showcase_tickets_resource.rb"))
    policy = File.read(File.join(destination_root, "app/policies/krudmin_ai_showcase/ticket_policy.rb"))
    workflow = File.read(File.join(destination_root, "app/services/krudmin_ai_showcase/ticket_workflow.rb"))
    dashboard = File.read(File.join(destination_root, "app/dashboards/krudmin_ai_showcase/tickets_dashboard.rb"))
    seeds = File.read(File.join(destination_root, "db/seeds/krudmin_ai_showcase.rb"))

    expect(resource).to include("tenant_scope", "policy_scope", "filter(:state)", "authorize(:destroy)")
    expect(policy).to include("assign_to_me?", "resolve?", "record.tenant == user.current_tenant")
    expect(workflow).to include("TicketPolicy.new", "MutationPipeline", "assign_to_me", "resolve")
    expect(dashboard).to include("Widgets::Count", "Widgets::Table", "Widgets::Summary")
    expect(seeds).to include("northwind", "southwind")
    expect(File).to exist(File.join(destination_root, "db/migrate/20260912000000_create_krudmin_ai_showcase_tickets.rb"))
    expect(File).to exist(File.join(destination_root, "docs/krudmin_ai_showcase_agent_playbook.md"))
    expect(File).to exist(File.join(destination_root, ".krudmin_ai/showcase_manifest.json"))
  end

  it "does not duplicate showcase routes when rerun" do
    contract = described_class.new(destination_root:, source_root:)
    contract.install
    contract.install

    routes = File.read(File.join(destination_root, "config/routes.rb"))
    expect(routes.scan("resources :showcase_tickets").length).to eq(1)
  end
end