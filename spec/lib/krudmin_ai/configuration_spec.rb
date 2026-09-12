require "spec_helper"
require "krudmin_ai/configuration"

RSpec.describe KrudminAI::Configuration do
  it "exposes host-provider configuration points" do
    configuration = described_class.new
    configuration.authentication_provider = :host_authentication
    configuration.tenant_provider = :host_tenancy

    expect(configuration).to have_attributes(
      authentication_provider: :host_authentication,
      tenant_provider: :host_tenancy,
      authorization_provider: nil,
      audit_provider: nil
    )
  end
end