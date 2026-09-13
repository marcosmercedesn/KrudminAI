require "json"
require "spec_helper"
require "yaml"

RSpec.describe "KrudminAI compatibility contract" do
  let(:root) { File.expand_path("../../..", __dir__) }
  let(:specification) { Gem::Specification.load(File.join(root, "krudmin_ai.gemspec")) }
  let(:registry) { JSON.parse(File.read(File.join(root, "docs/capability_registry.json"))) }

  it "matches the published Rails and Ruby support window", :aggregate_failures do
    rails = specification.dependencies.find { |dependency| dependency.name == "rails" }.requirement

    expect(specification.required_ruby_version).to eq(Gem::Requirement.new(">= 3.3"))
    expect(rails.satisfied_by?(Gem::Version.new("8.1.3"))).to be(true)
    expect(rails.satisfied_by?(Gem::Version.new("8.0.9"))).to be(false)
    expect(rails.satisfied_by?(Gem::Version.new("10.0.0"))).to be(false)
    expect(registry.fetch("compatibility")).to include("rails" => ">= 8.1, < 10.0", "ruby" => ">= 3.3")
  end

  it "retains Rails 8.1 ERB 4.x and JSON compatibility caps", :aggregate_failures do
    erb = specification.dependencies.find { |dependency| dependency.name == "erb" }.requirement
    json = specification.dependencies.find { |dependency| dependency.name == "json" }.requirement

    expect(erb.satisfied_by?(Gem::Version.new("4.0.0"))).to be(true)
    expect(erb.satisfied_by?(Gem::Version.new("5.0.0"))).to be(false)
    expect(json.satisfied_by?(Gem::Version.new("2.0.0"))).to be(true)
    expect(json.satisfied_by?(Gem::Version.new("3.0.0"))).to be(false)
  end

  it "keeps the CI matrix synchronized with published compatibility lanes" do
    workflow = YAML.load_file(File.join(root, ".github/workflows/ci.yml"))
    lanes = workflow.fetch("jobs").fetch("test").fetch("strategy").fetch("matrix").fetch("include")
    actual = lanes.to_h { |lane| [ lane.fetch("name"), lane.slice("ruby", "rails", "allow_failure") ] }

    expect(actual).to eq(
      "minimum" => { "ruby" => "3.3", "rails" => "~> 8.1.3" },
      "stable" => { "ruby" => "3.4", "rails" => ">= 8.1, < 10.0" },
      "latest" => { "ruby" => "4.0", "rails" => ">= 8.1, < 10.0" },
      "preview" => { "ruby" => "head", "rails" => ">= 9.0.a", "allow_failure" => true }
    )
  end
end
