require "spec_helper"
require "krudmin_ai/version"

RSpec.describe KrudminAI do
  it "exposes a prerelease version during contract definition" do
    expect(KrudminAI::VERSION).to eq("0.1.0.pre.1")
  end
end
