require "krudmin_ai/fields/string"

module KrudminAI
  module Fields
    class Masked < String
      def list_value(_record) = "[REDACTED]"
      def show_value(_record) = "[REDACTED]"
      def json_value(_record) = nil
      def export_value(_record) = nil
      def ai_value(_record) = nil
      def serializable? = false

      def revealable?(record, context)
        resource.field_revealable?(attribute, record, context)
      end
    end
  end
end
