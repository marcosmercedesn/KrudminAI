require "spec_helper"
require "aasm"
require "krudmin_ai/resources/base"

RSpec.describe KrudminAI::Fields::StateMachine do
  Event = Data.define(:name)
  State = Data.define(:name)

  let(:model_class) do
    Class.new do
      def self.aasm = Struct.new(:states).new([ State.new(:draft), State.new(:submitted) ])

      attr_accessor :status

      def initialize(status = "draft") = @status = status
      def aasm
        Class.new do
          define_method(:events) { |permitted:| permitted ? [ Event.new(:submit) ] : [] }
        end.new
      end
    end
  end

  let(:resource) do
    model = model_class
    Class.new(KrudminAI::Resources::Base) do
      model model
      field :status, :state_machine
    end
  end

  it "discovers states and currently permitted events from a compatible host machine" do
    adapter = resource.field_adapter(:status)

    expect(adapter.filter_definition).to eq(type: :select, options: %w[draft submitted])
    expect(adapter.permitted_events(model_class.new)).to eq([ :submit ])
  end

  it "supports labels while rejecting direct state writes by default" do
    labeled_resource = Class.new(KrudminAI::Resources::Base) do
      field :status, :state_machine,
        states: { draft: "Draft", submitted: "In review" },
        transition_labels: { submit_for_review: "Send for review" }
    end
    adapter = labeled_resource.field_adapter(:status)

    expect(adapter.show_value(model_class.new("submitted"))).to eq("In review")
    expect(adapter.transition_label(:submit_for_review)).to eq("Send for review")
    expect(adapter.transition_label(:return_to_draft)).to eq("Return To Draft")
    expect { adapter.parameter("submitted") }.to raise_error(ArgumentError, "status must be changed through a declared transition")
    expect(adapter).not_to be_validation_projectable
  end

  it "fails closed without configured states or a compatible host machine" do
    incompatible_model = Class.new
    incompatible_resource = Class.new(KrudminAI::Resources::Base) do
      model incompatible_model
      field :status, :state_machine
    end

    expect { incompatible_resource.field_adapter(:status) }
      .to raise_error(KrudminAI::Resources::ConfigurationError, /requires states or a compatible model machine/)
  end

  it "discovers states and events from a named AASM machine" do
    model = Class.new do
      include AASM
      attr_accessor :review_state

      aasm(:review, column: :review_state) do
        state :pending, initial: true
        state :accepted
        event(:accept) { transitions from: :pending, to: :accepted }
      end
    end
    named_resource = Class.new(KrudminAI::Resources::Base) do
      model model
      field :review_state, :state_machine, machine: :review
    end
    record = model.new

    expect(named_resource.field_adapter(:review_state).filter_definition).to eq(type: :select, options: %w[pending accepted])
    expect(named_resource.field_adapter(:review_state).permitted_events(record)).to eq([ :accept ])
  end

  it "normalizes configured state colors to supported badge variants" do
    colored_resource = Class.new(KrudminAI::Resources::Base) do
      field :status, :state_machine, states: %i[draft submitted], colors: { draft: :warning, submitted: :unknown }
    end

    expect(colored_resource.field_adapter(:status).badge_variant(model_class.new("draft"))).to eq(:warning)
    expect(colored_resource.field_adapter(:status).badge_variant(model_class.new("submitted"))).to eq(:default)
  end
end