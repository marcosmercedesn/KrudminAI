require "spec_helper"
require "krudmin_ai/resources/base"
require "krudmin_ai/access_context"

RSpec.describe KrudminAI::Validations::Introspector do
  ValidationColumn = Data.define(:type, :null, :default, :limit, :scale) do
    def initialize(type:, null: true, default: nil, limit: nil, scale: nil) = super
  end

  FakeValidator = Data.define(:kind, :options) do
    def initialize(kind:, options: {}) = super
  end

  class ValidationRecord
    def initialize(errors: nil)
      @errors = errors
    end

    attr_reader :errors
  end

  # Mirrors the ActiveModel::Errors surface the introspector relies on.
  class FakeErrors
    MESSAGES = {
      blank: "can't be blank", too_short: "is too short (minimum is %{count} characters)",
      too_long: "is too long (maximum is %{count} characters)", wrong_length: "is the wrong length",
      not_a_number: "is not a number", not_an_integer: "must be an integer",
      greater_than: "must be greater than %{count}", less_than_or_equal_to: "must be less than or equal to %{count}",
      invalid: "is invalid", inclusion: "is not included in the list", exclusion: "is reserved",
      confirmation: "doesn't match %{attribute}", odd: "must be odd", even: "must be even"
    }.freeze

    def generate_message(_attribute, key, options = {})
      template = MESSAGES.fetch(key)
      template.gsub(/%\{(\w+)\}/) { options.fetch(Regexp.last_match(1).to_sym).to_s }
    end

    def full_message(attribute, message) = "#{attribute.to_s.tr('_', ' ').capitalize} #{message}"
  end

  let(:context) { KrudminAI::AccessContext.new(actor: :operator, tenant: :north, roles: [ :operator ]) }
  let(:record) { ValidationRecord.new(errors: FakeErrors.new) }

  def build_resource(columns: {}, validators: {}, &block)
    model = Class.new do
      define_singleton_method(:columns_hash) { columns }
      define_singleton_method(:validators_on) { |attribute| validators.fetch(attribute.to_sym, []) }
      define_singleton_method(:human_attribute_name) { |name| name.to_s.tr("_", " ").capitalize }
    end

    Class.new(KrudminAI::Resources::Base) do
      model model
      instance_eval(&block) if block
    end
  end

  def permit(resource, *attributes)
    attributes.each { |attribute| resource.authorize_field(attribute, read: ->(*) { true }, write: ->(*) { true }) }
    resource
  end

  describe "authorization" do
    it "emits nothing when the field read or write decision is denied" do
      resource = build_resource(validators: { title: [ FakeValidator.new(kind: :presence) ] })
      resource.authorize_field(:title, read: ->(*) { true }, write: ->(*) { false })

      expect(resource.validation_rules(:title, record, context)).to eq({})
    end

    it "emits nothing when no field authorizer is declared" do
      resource = build_resource(validators: { title: [ FakeValidator.new(kind: :presence) ] })

      expect(resource.validation_rules(:title, record, context)).to eq({})
    end

    it "emits nothing for password and hidden adapters" do
      resource = build_resource(validators: { secret: [ FakeValidator.new(kind: :presence) ], token: [ FakeValidator.new(kind: :presence) ] }) do
        field :secret, :password
        field :token, :hidden
      end
      permit(resource, :secret, :token)

      expect(resource.validation_rules(:secret, record, context)).to eq({})
      expect(resource.validation_rules(:token, record, context)).to eq({})
    end

    it "emits nothing for computed adapters" do
      resource = build_resource { field :total, :computed, value: ->(_record) { 1 } }
      permit(resource, :total)

      expect(resource.validation_rules(:total, record, context)).to eq({})
    end
  end

  describe "supported validators" do
    it "projects presence, length, numericality, format, inclusion, exclusion, and confirmation" do
      resource = build_resource(validators: {
        title: [ FakeValidator.new(kind: :presence), FakeValidator.new(kind: :length, options: { minimum: 3, maximum: 80 }) ],
        size: [ FakeValidator.new(kind: :length, options: { is: 5 }) ],
        span: [ FakeValidator.new(kind: :length, options: { in: 2..9 }) ],
        rank: [ FakeValidator.new(kind: :numericality, options: { only_integer: true, greater_than: 0, less_than_or_equal_to: 10, odd: true }) ],
        slug: [ FakeValidator.new(kind: :format, options: { with: /\A[a-z0-9-]+\z/ }) ],
        state: [ FakeValidator.new(kind: :inclusion, options: { in: %w[draft published] }) ],
        handle: [ FakeValidator.new(kind: :exclusion, options: { in: %w[admin root] }) ],
        contact: [ FakeValidator.new(kind: :confirmation) ]
      })
      permit(resource, :title, :size, :span, :rank, :slug, :state, :handle, :contact)

      expect(resource.validation_rules(:title, record, context)).to include(required: true, minimum: 3, maximum: 80)
      expect(resource.validation_rules(:size, record, context)).to include(is: 5)
      expect(resource.validation_rules(:span, record, context)).to include(minimum: 2, maximum: 9)
      expect(resource.validation_rules(:rank, record, context)).to include(numeric: true, only_integer: true, greater_than: 0, less_than_or_equal_to: 10, parity: :odd)
      expect(resource.validation_rules(:slug, record, context)).to include(pattern: "^[a-z0-9-]+$")
      expect(resource.validation_rules(:state, record, context)).to include(one_of: %w[draft published])
      expect(resource.validation_rules(:handle, record, context)).to include(none_of: %w[admin root])
      expect(resource.validation_rules(:contact, record, context)).to include(confirms: "contact_confirmation")
    end

    it "projects acceptance only on boolean adapters" do
      resource = build_resource(validators: {
        terms: [ FakeValidator.new(kind: :acceptance) ], note: [ FakeValidator.new(kind: :acceptance) ]
      }) { field :terms, :boolean }
      permit(resource, :terms, :note)

      expect(resource.validation_rules(:terms, record, context)).to include(required: true)
      expect(resource.validation_rules(:note, record, context)).to eq({})
    end
  end

  describe "server-only validators" do
    it "drops uniqueness, custom, and conditional validators" do
      resource = build_resource(validators: {
        email: [ FakeValidator.new(kind: :uniqueness) ],
        code: [ FakeValidator.new(kind: :tenant_scoped_code) ],
        title: [ FakeValidator.new(kind: :presence, options: { if: :published? }) ],
        slug: [ FakeValidator.new(kind: :presence, options: { unless: :draft? }) ],
        name: [ FakeValidator.new(kind: :presence, options: { on: :create }) ]
      })
      permit(resource, :email, :code, :title, :slug, :name)

      %i[email code title slug name].each do |attribute|
        expect(resource.validation_rules(attribute, record, context)).to eq({})
      end
    end

    it "drops non-literal inclusion and exclusion sets" do
      resource = build_resource(validators: {
        level: [ FakeValidator.new(kind: :inclusion, options: { in: 1..5 }) ],
        tier: [ FakeValidator.new(kind: :exclusion, options: { in: ->(_record) { [] } }) ]
      })
      permit(resource, :level, :tier)

      expect(resource.validation_rules(:level, record, context)).to eq({})
      expect(resource.validation_rules(:tier, record, context)).to eq({})
    end
  end

  describe "regex portability" do
    def pattern_for(regexp)
      resource = build_resource(validators: { slug: [ FakeValidator.new(kind: :format, options: { with: regexp }) ] })
      permit(resource, :slug)
      resource.validation_rules(:slug, record, context)[:pattern]
    end

    it "translates fully string-anchored patterns" do
      expect(pattern_for(/\A\d{4}\z/)).to eq("^\\d{4}$")
      expect(pattern_for(/\A[a-z]+\Z/)).to eq("^[a-z]+$")
      expect(pattern_for(/[a-z]+/)).to eq("[a-z]+")
    end

    it "drops line-anchored and Ruby-only patterns" do
      expect(pattern_for(/^\d+$/)).to be_nil
      expect(pattern_for(/\A(?<year>\d{4})\z/)).to be_nil
      expect(pattern_for(/\A[[:alpha:]]+\z/)).to be_nil
      expect(pattern_for(/\A\p{Alpha}+\z/)).to be_nil
      expect(pattern_for(/\A\h+\z/)).to be_nil
      expect(pattern_for(/\Aabc\z/m)).to be_nil
      expect(pattern_for(/\A without \z/x)).to be_nil
    end

    it "drops a rule when the format uses an unsupported option" do
      resource = build_resource(validators: { slug: [ FakeValidator.new(kind: :format, options: { without: /\Aadmin\z/ }) ] })
      permit(resource, :slug)

      expect(resource.validation_rules(:slug, record, context)).to eq({})
    end
  end

  describe "column metadata" do
    it "derives required, maximum, and step from the schema" do
      columns = {
        "title" => ValidationColumn.new(type: :string, null: false, limit: 80),
        "price" => ValidationColumn.new(type: :decimal, scale: 2)
      }
      resource = build_resource(columns:) { field :price, :decimal }
      permit(resource, :title, :price)

      expect(resource.validation_rules(:title, record, context)).to include(required: true, maximum: 80)
      expect(resource.validation_rules(:price, record, context)).to include(step: "0.01")
    end

    it "does not infer required from a defaulted or boolean column" do
      columns = {
        "state" => ValidationColumn.new(type: :string, null: false, default: "draft"),
        "active" => ValidationColumn.new(type: :boolean, null: false)
      }
      resource = build_resource(columns:) { field :active, :boolean }
      permit(resource, :state, :active)

      expect(resource.validation_rules(:state, record, context)).not_to include(:required)
      expect(resource.validation_rules(:active, record, context)).not_to include(:required)
    end
  end

  describe "adapter constraints" do
    it "contributes the type semantics each adapter already enforces" do
      resource = build_resource do
        field :email, :email
        field :published_on, :date
        field :starts_at, :datetime
        field :opens_at, :time
        field :payload, :json
        field :state, :enum, values: %w[draft published], allow_blank: false
        field :count, :number
        field :tags, :has_many_ids, resource: nil, label_read: ->(*) { true }
      end
      permit(resource, :email, :published_on, :starts_at, :opens_at, :payload, :state, :count, :tags)

      expect(resource.validation_rules(:email, record, context)).to include(type: :email)
      expect(resource.validation_rules(:published_on, record, context)).to include(type: :date)
      expect(resource.validation_rules(:starts_at, record, context)).to include(type: :datetime)
      expect(resource.validation_rules(:opens_at, record, context)).to include(type: :time)
      expect(resource.validation_rules(:payload, record, context)).to include(type: :json)
      expect(resource.validation_rules(:state, record, context)).to include(one_of: %w[draft published], required: true)
      expect(resource.validation_rules(:count, record, context)).to include(numeric: true, only_integer: true, step: 1)
      expect(resource.validation_rules(:tags, record, context)).to include(multiple: true)
    end

    it "marks a belongs-to required only when the blank option is withheld" do
      resource = build_resource do
        field :owner_id, :belongs_to, resource: nil, label_read: ->(*) { true }, include_blank: false
        field :editor_id, :belongs_to, resource: nil, label_read: ->(*) { true }
      end
      permit(resource, :owner_id, :editor_id)

      expect(resource.validation_rules(:owner_id, record, context)).to include(required: true)
      expect(resource.validation_rules(:editor_id, record, context)).to eq({})
    end
  end

  describe "merging" do
    it "keeps the most restrictive bound when sources disagree" do
      columns = { "title" => ValidationColumn.new(type: :string, limit: 255) }
      validators = { title: [ FakeValidator.new(kind: :length, options: { maximum: 80, minimum: 2 }), FakeValidator.new(kind: :length, options: { minimum: 5 }) ] }
      resource = build_resource(columns:, validators:)
      permit(resource, :title)

      expect(resource.validation_rules(:title, record, context)).to include(maximum: 80, minimum: 5)
    end

    it "intersects allowed value sets" do
      validators = { state: [ FakeValidator.new(kind: :inclusion, options: { in: %w[draft published archived] }) ] }
      resource = build_resource(validators:) { field :state, :enum, values: %w[draft published] }
      permit(resource, :state)

      expect(resource.validation_rules(:state, record, context)[:one_of]).to eq(%w[draft published])
    end
  end

  describe "messages" do
    it "generates full messages through the record's own error catalog" do
      validators = { title: [ FakeValidator.new(kind: :presence), FakeValidator.new(kind: :length, options: { maximum: 80 }) ] }
      resource = build_resource(validators:)
      permit(resource, :title)

      messages = resource.validation_rules(:title, record, context)[:messages]
      expect(messages[:required]).to eq("Title can't be blank")
      expect(messages[:maximum]).to eq("Title is too long (maximum is 80 characters)")
    end

    it "omits messages when the record cannot generate them" do
      validators = { title: [ FakeValidator.new(kind: :presence) ] }
      resource = build_resource(validators:)
      permit(resource, :title)

      rules = resource.validation_rules(:title, ValidationRecord.new, context)
      expect(rules).to include(required: true)
      expect(rules).not_to include(:messages)
    end
  end

  describe "nested relationships" do
    let(:child) do
      Class.new do
        define_singleton_method(:columns_hash) { {} }
        define_singleton_method(:validators_on) { |_attribute| [ FakeValidator.new(kind: :presence) ] }
        define_singleton_method(:human_attribute_name) { |name| name.to_s.capitalize }

        def errors = FakeErrors.new
      end.new
    end

    def build_relationship(field_authorizers)
      KrudminAI::Resources::Relationship.new(
        name: :passengers, fields: %i[name], label: "Passengers", display_fields: %i[name],
        maximum: 5, order: nil, authorizer: ->(*) { true }, tenant_record_handler: ->(*) { true },
        field_authorizers:
      )
    end

    it "projects the child model's validators through the relationship's own authorizers" do
      relationship = build_relationship(name: { read: ->(*) { true }, write: ->(*) { true } })

      rules = relationship.validation_rules(:name, child, context, build_resource)
      expect(rules).to include(required: true)
      expect(rules[:messages][:required]).to eq("Name can't be blank")
    end

    it "emits nothing when the nested field write decision is denied" do
      relationship = build_relationship(name: { read: ->(*) { true }, write: ->(*) { false } })

      expect(relationship.validation_rules(:name, child, context, build_resource)).to eq({})
    end

    it "falls back to a text adapter for an undeclared nested field" do
      relationship = build_relationship(name: { read: ->(*) { true }, write: ->(*) { true } })

      expect(relationship.form_adapter(:name, build_resource)).to be_a(KrudminAI::Fields::String)
    end
  end
end
