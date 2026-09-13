require "krudmin_ai/fields/adapter"

module KrudminAI
  module Fields
    class String < Adapter
      def filter_definition = { type: :text, operators: %i[contains equals starts_with ends_with] }
    end
  end
end
