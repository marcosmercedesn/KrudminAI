require "spec_helper"
require "krudmin_ai/resources/relationship"
require "krudmin_ai/resources/base"

RSpec.describe KrudminAI::Resources::Base do
  let(:resource) do
    Class.new(described_class) do
      has_many :passengers,
        fields: %i[name age],
        label: "Passengers",
        display: [:name],
        maximum: 4,
        order: :position,
        authorize: ->(_record, _action, _context) { true },
        tenant_record: ->(_record, _context) { true },
        field_authorizers: {
          name: { read: ->(_record, _context) { true }, write: ->(_record, _context) { true } }
        }
    end
  end

  it "declares permitted nested fields and association constraints" do
    relationship = resource.relationships.fetch(:passengers)

    expect(relationship).to have_attributes(fields: %i[name age], display_fields: [:name], label: "Passengers", maximum: 4, order: :position)
    expect(resource.nested_permitted_attributes).to eq([{ passengers_attributes: %i[id _destroy name age] }])
    expect(relationship).to be_field_readable(:name, Object.new, Object.new)
    expect(relationship).to be_field_writable(:name, Object.new, Object.new)
    expect(relationship).not_to be_field_readable(:age, Object.new, Object.new)
    expect(relationship).not_to be_field_writable(:age, Object.new, Object.new)
    expect(relationship.readable_display_fields(Object.new, Object.new)).to eq([:name])
  end

  it "requires child authorization and tenant checks" do
    expect do
      Class.new(described_class) { has_many :passengers, fields: [:name] }
    end.to raise_error(ArgumentError, "A child authorization handler is required")
  end
end