require "fileutils"

module KrudminAI
  module Generators
    class FileWriter
      def initialize(destination_root)
        @destination_root = destination_root
      end

      def write(path, contents)
        absolute_path = File.join(destination_root, path)
        FileUtils.mkdir_p(File.dirname(absolute_path))
        File.write(absolute_path, contents) unless File.exist?(absolute_path) && File.read(absolute_path) == contents
      end

      def create(path, contents)
        absolute_path = File.join(destination_root, path)
        return if File.exist?(absolute_path)

        write(path, contents)
      end

      def replace_managed_block(path, marker:, contents:, inside_routes: false)
        absolute_path = File.join(destination_root, path)
        start_marker = "# BEGIN #{marker}"
        end_marker = "# END #{marker}"
        block = [start_marker, contents.rstrip, end_marker].join("\n") + "\n"
        existing = File.exist?(absolute_path) ? File.read(absolute_path) : ""
        pattern = /#{Regexp.escape(start_marker)}.*?#{Regexp.escape(end_marker)}\n?/m
        replacement = if existing.match?(pattern)
          existing.sub(pattern, block)
        elsif inside_routes && (closing_index = existing.rindex("\nend"))
          existing.dup.insert(closing_index + 1, "\n#{block}")
        elsif existing.empty?
          block
        else
          separator = existing.end_with?("\n") ? "\n" : "\n\n"
          "#{existing}#{separator}#{block}"
        end
        write(path, replacement)
      end

      private

      public

      attr_reader :destination_root
    end
  end
end