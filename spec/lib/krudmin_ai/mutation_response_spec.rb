require "spec_helper"
require "krudmin_ai/mutation_pipeline"
require "krudmin_ai/mutation_response"

RSpec.describe KrudminAI::MutationResponseAdapter do
  it "maps every failed mutation outcome consistently for HTML, JSON, and Turbo Stream" do
    expected_statuses = {
      unauthenticated: 401,
      tenant_required: 403,
      forbidden: 403,
      invalid: 422,
      configuration_error: 500,
      audit_failed: 500,
      persistence_failed: 500
    }

    expected_statuses.each do |outcome, status|
      result = KrudminAI::MutationResult.new(:update, outcome, nil, [{ code: outcome }], nil)

      %i[html json turbo_stream].each do |format|
        response = described_class.for(result, format:)

        expect(response.status).to eq(status)
        expect(response.payload.fetch(:errors)).to eq([{ code: outcome }]) unless format == :html
      end
    end
  end

  it "uses create-specific success statuses and a stable JSON envelope" do
    result = KrudminAI::MutationResult.new(:create, :success, { id: 7 }, [], :event)

    expect(described_class.for(result, format: :html)).to have_attributes(status: 303)
    expect(described_class.for(result, format: :json)).to have_attributes(
      status: 201,
      payload: { data: { id: 7 }, errors: [], outcome: :success }
    )
    expect(described_class.for(result, format: :turbo_stream).payload.fetch(:template))
      .to eq("krudmin_ai/mutations/create_success")
  end
end