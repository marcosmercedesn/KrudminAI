require "spec_helper"
require "krudmin_ai/resources/base"
require "krudmin_ai/fields/registry"

RSpec.describe "media field adapters" do
  RichContent = Struct.new(:text) do
    def to_plain_text = text
  end
  Attachment = Struct.new(:filename)

  class MediaHostModel
    def self.rich_text_association_names = [ "notes" ]
    def self.attachment_reflections = { "avatar" => Object.new }
  end

  it "requires declared Action Text and Active Storage host contracts" do
    resource = Class.new(KrudminAI::Resources::Base) do
      model MediaHostModel
      field :notes, :rich_text
      field :avatar, :image
      field :label, :computed, value: ->(record) { "Member: #{record.name}" }
    end
    record = Struct.new(:notes, :avatar, :name).new(RichContent.new("Private notes"), Attachment.new("avatar.png"), "Mina")

    expect(resource.field_adapter(:notes).show_value(record)).to eq("Private notes")
    expect(resource.field_adapter(:avatar).show_value(record)).to eq("avatar.png")
    expect(resource.field_adapter(:label).show_value(record)).to eq("Member: Mina")
    expect { resource.field_adapter(:label).parameter("forged") }.to raise_error(ArgumentError)
  end

  it "fails closed when the host has not declared the required integration" do
    resource = Class.new(KrudminAI::Resources::Base) do
      model Class.new
      field :notes, :rich_text
      field :avatar, :file
    end
    form = double("form")

    expect { resource.field_adapter(:notes).form_control(form, writable: true, errors: [], access_note_id: "notes-note") }.to raise_error(KrudminAI::Resources::ConfigurationError)
    expect { resource.field_adapter(:avatar).form_control(form, writable: true, errors: [], access_note_id: "avatar-note") }.to raise_error(KrudminAI::Resources::ConfigurationError)
  end
end
