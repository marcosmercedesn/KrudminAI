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
      result = KrudminAI::MutationResult.new(:update, outcome, nil, [ { code: outcome } ], nil)

      %i[html json turbo_stream].each do |format|
        response = described_class.for(result, format:)

        expect(response.status).to eq(status)
        expect(response.payload.fetch(:errors)).to eq([ { code: outcome } ]) unless format == :html
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

  it "redirects with see-other for every successful HTML mutation so Turbo does not repeat the request" do
    %i[create update destroy archive restore].each do |operation|
      result = KrudminAI::MutationResult.new(operation, :success, { id: 7 }, [], :event)

      expect(described_class.for(result, format: :html)).to have_attributes(status: 303)
    end
  end

  it "answers a successful Turbo Stream mutation with 200 and the operation's template" do
    %i[create update destroy archive restore].each do |operation|
      result = KrudminAI::MutationResult.new(operation, :success, { id: 7 }, [], :event)
      response = described_class.for(result, format: :turbo_stream)

      expect(response.status).to eq(200)
      expect(response.payload.fetch(:template)).to eq("krudmin_ai/mutations/#{operation}_success")
    end
  end

  it "answers a rejected Turbo Stream mutation with the operation's error template" do
    %i[create update destroy archive restore].each do |operation|
      result = KrudminAI::MutationResult.new(operation, :invalid, nil, [ { code: :invalid, detail: "bad" } ], nil)
      response = described_class.for(result, format: :turbo_stream)

      expect(response.status).to eq(422)
      expect(response.payload.fetch(:template)).to eq("krudmin_ai/mutations/#{operation}_error")
    end
  end

  it "rejects a format it cannot render rather than guessing one" do
    result = KrudminAI::MutationResult.new(:update, :success, { id: 7 }, [], :event)

    expect { described_class.for(result, format: :xml) }.to raise_error(ArgumentError, /Unsupported response format/)
  end
end
