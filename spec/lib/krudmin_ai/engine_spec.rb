require "rails_helper"

RSpec.describe KrudminAI::Engine do
  it "is an isolated Rails engine" do
    expect(described_class).to be < Rails::Engine
    expect(described_class.isolated?).to be(true)
  end
end