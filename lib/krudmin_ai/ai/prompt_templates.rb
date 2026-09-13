module KrudminAI
  module Ai
    PromptTemplate = Data.define(:name, :task, :instructions)

    class PromptTemplates
      def initialize
        @templates = {}
      end

      def register(name, task:, instructions:)
        raise ArgumentError, "Template instructions are required" if instructions.to_s.strip.empty?

        templates[name.to_sym] = PromptTemplate.new(name.to_sym, task.to_sym, instructions.freeze)
      end

      def fetch(name, task:)
        template = templates.fetch(name.to_sym)
        raise ArgumentError, "Template does not support this task" unless template.task == task.to_sym

        template
      end

      private

      attr_reader :templates
    end
  end
end
