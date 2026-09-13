require "krudmin_ai/fields/string"
require "krudmin_ai/fields/scalar"
require "krudmin_ai/fields/sensitive"
require "krudmin_ai/fields/media"
require "krudmin_ai/fields/belongs_to"
require "krudmin_ai/fields/remote_belongs_to"
require "krudmin_ai/fields/has_many_ids"

module KrudminAI
  module Fields
    class Registry
      class << self
        def register(name, adapter)
          raise ArgumentError, "A field adapter class is required" unless adapter.is_a?(Class) && adapter <= Adapter

          adapters[name.to_sym] = adapter
        end

        def resolve(resource, attribute)
          definition = resource.field_definition(attribute)
          type = definition.fetch(:type) { inferred_type(resource.model_class, attribute) }
          adapter_class = adapters.fetch(type.to_sym) { raise Resources::ConfigurationError, "Unknown field adapter: #{type}" }
          adapter_class.new(resource:, attribute:, options: definition.fetch(:options))
        end

        def inferred_type(model_class, attribute)
          column = model_class.columns_hash[attribute.to_s] if model_class.respond_to?(:columns_hash)
          {
            text: :text, integer: :number, bigint: :number, float: :decimal, decimal: :decimal,
            boolean: :boolean, date: :date, time: :time, datetime: :datetime, json: :json, jsonb: :json
          }.fetch(column&.type, :string)
        end

        private

        def adapters
          @adapters ||= {
            string: String, text: Text, email: Email, password: Password, hidden: Hidden, number: Number,
            decimal: Decimal, currency: Currency, percentage: Percentage, boolean: Boolean, date: Date,
            time: Time, datetime: DateTime, json: Json, enum: Enum, identifier: Identifier, masked: Masked,
            rich_text: RichText, file: File, image: Image, computed: Computed,
            belongs_to: BelongsTo, remote_belongs_to: RemoteBelongsTo, has_many_ids: HasManyIds
          }
        end
      end
    end
  end
end
