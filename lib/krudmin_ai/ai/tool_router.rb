module KrudminAI
  module Ai
    class UnsafeToolCall < StandardError; end

    class ToolRouter
      READ_ONLY_TOOLS = %i[record_summary record_q_and_a document_summary report_insight].freeze

      def validate!(tool_calls, mutation_approved: false)
        Array(tool_calls).each do |tool_call|
          name = tool_call.fetch(:name).to_sym
          next if READ_ONLY_TOOLS.include?(name)
          next if name == :mutation && mutation_approved

          raise UnsafeToolCall, "Tool call is not permitted: #{name}"
        end
      end
    end
  end
end
