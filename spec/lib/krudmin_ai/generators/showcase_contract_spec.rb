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
    controller = File.read(File.join(destination_root, "app/controllers/admin/showcase_tickets_controller.rb"))
    dashboard = File.read(File.join(destination_root, "app/dashboards/krudmin_ai_showcase/tickets_dashboard.rb"))
    seeds = File.read(File.join(destination_root, "db/seeds/krudmin_ai_showcase.rb"))

    scenario = File.read(File.join(destination_root, "test/integration/krudmin_ai_showcase_test.rb"))

    expect(resource).to include("tenant_scope", "policy_scope", "filter(:state)", "authorize(:destroy)", "action :assign_to_me", "transition :resolve")
      expect(resource).to include("KrudminAIShowcase::Ticket")
      expect(policy).to include("module KrudminAIShowcase", "assign_to_me?", "resolve?", "record.tenant == user.tenant")
    expect(controller).to include("< KrudminAI::ResourceController", "resource ShowcaseTicketsResource")
    expect(dashboard).to include("Dashboards::Base", "Widgets::Count", "Widgets::Table")
    expect(scenario).to include("scopes tenant workflow data", "manager transitions", "register_showcase_navigation", "krudmin-ai-shell")
    expect(File.read(File.join(destination_root, "db/migrate/20260912000000_create_krudmin_ai_showcase_tickets.rb"))).to include("CreateKrudminAIShowcaseTickets")
    expect(seeds).to include("northwind", "southwind")
    expect(File).to exist(File.join(destination_root, "db/migrate/20260912000000_create_krudmin_ai_showcase_tickets.rb"))
    expect(File).to exist(File.join(destination_root, "docs/krudmin_ai_showcase_agent_playbook.md"))
    expect(File).to exist(File.join(destination_root, ".krudmin_ai/showcase_manifest.json"))
  end

  it "installs a lightweight mode without full dashboard or scenario artifacts" do
    described_class.new(destination_root:, source_root:, mode: "lightweight").install

    expect(File).to exist(File.join(destination_root, "app/resources/showcase_tickets_resource.rb"))
    expect(File).not_to exist(File.join(destination_root, "app/dashboards/krudmin_ai_showcase/tickets_dashboard.rb"))
    expect(File).not_to exist(File.join(destination_root, "test/integration/krudmin_ai_showcase_test.rb"))
    manifest = JSON.parse(File.read(File.join(destination_root, ".krudmin_ai/showcase_manifest.json")))
    expect(manifest).to include("mode" => "lightweight")
  end

  it "does not duplicate showcase routes when rerun" do
    FileUtils.mkdir_p(File.join(destination_root, "config"))
    File.write(File.join(destination_root, "config/routes.rb"), "Rails.application.routes.draw do\nend\n")
    contract = described_class.new(destination_root:, source_root:)
    contract.install
    contract.install

    routes = File.read(File.join(destination_root, "config/routes.rb"))
    expect(routes.scan("resources :showcase_tickets").length).to eq(1)
    expect(routes).to end_with("# END KRUDMIN_AI_SHOWCASE_ROUTES\nend\n")
  end
end
