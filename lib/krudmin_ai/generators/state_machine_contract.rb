require "active_support/core_ext/string/inflections"
require "krudmin_ai/generators/file_writer"
require "krudmin_ai/generators/host_manifest"

module KrudminAI
  module Generators
    class StateMachineContract
      DEFAULT_STATES = %w[draft submitted approved rejected paid].freeze
      DEFAULT_EVENTS = %w[submit:draft:submitted approve:submitted:approved reject:submitted:rejected pay:approved:paid].freeze

      def initialize(destination_root:, name:, resource: nil, attribute: "status", machine: "default", states: DEFAULT_STATES, events: DEFAULT_EVENTS)
        @destination_root = destination_root
        @writer = FileWriter.new(destination_root)
        @name = name.underscore
        @resource = (resource || name).underscore.pluralize
        @attribute = attribute.underscore.to_sym
        @machine = machine.to_sym
        @states = Array(states).map { |state| state.to_s.underscore.to_sym }.uniq
        @events = parse_events(events)
        validate!
      end

      def install
        raise ArgumentError, "Generate the #{resource.camelize}Resource before its state machine" unless File.exist?(File.join(destination_root, resource_path))

        writer.create(concern_path, concern)
        writer.create(initializer_path, initializer)
        writer.create(test_path, test)
        writer.create(extension_path, resource_extension)
        writer.replace_managed_block(resource_path, marker:, contents: "require_relative \"#{extension_require_path}\"")
        manifest.enable("state_machines")
      end

      private

      attr_reader :destination_root, :writer, :name, :resource, :attribute, :machine, :states, :events

      def manifest
        @manifest ||= HostManifest.new(writer)
      end

      def parse_events(values)
        Array(values).map do |value|
          event_name, from, to = value.to_s.split(":", 3)
          raise ArgumentError, "Events must use name:from:to" if event_name.to_s.empty? || from.to_s.empty? || to.to_s.empty?

          { name: event_name.underscore.to_sym, from: from.underscore.to_sym, to: to.underscore.to_sym }
        end
      end

      def validate!
        raise ArgumentError, "At least one state is required" if states.empty?

        unknown_states = events.flat_map { |event| [ event[:from], event[:to] ] }.uniq - states
        raise ArgumentError, "Events reference unknown states: #{unknown_states.join(', ')}" if unknown_states.any?
      end

      def model_class = name.camelize
      def workflow_module = "#{model_class}Workflow"
      def concern_path = "app/models/concerns/#{name}_workflow.rb"
      def initializer_path = "config/initializers/krudmin_ai_#{name}_workflow.rb"
      def test_path = "test/models/concerns/#{name}_workflow_test.rb"
      def resource_path = "app/resources/#{resource}_resource.rb"
      def extension_path = "app/resources/#{resource}_resource_state_machine.rb"
      def extension_require_path = "#{resource}_resource_state_machine"
      def marker = "KRUDMIN_AI_#{resource.upcase}_STATE_MACHINE_REQUIRE"

      def concern
        machine_declaration = machine == :default ? "aasm column: :#{attribute}" : "aasm(:#{machine}, column: :#{attribute}, namespace: :#{machine})"
        <<~RUBY
          module #{workflow_module}
            extend ActiveSupport::Concern

            included do
              include AASM

              #{machine_declaration} do
                state :#{states.first}, initial: true
                #{states.drop(1).map { |state| "state :#{state}" }.join("\n        ")}

                #{events.map { |event| "event(:#{event[:name]}) { transitions from: :#{event[:from]}, to: :#{event[:to]} }" }.join("\n        ")}
              end
            end
          end
        RUBY
      end

      def initializer
        <<~RUBY
          Rails.application.config.to_prepare do
            #{model_class}.include(#{workflow_module}) unless #{model_class} < #{workflow_module}
          end
        RUBY
      end

      def resource_extension
        machine_option = machine == :default ? "" : ", machine: :#{machine}"
        declarations = events.map do |event|
          method_suffix = machine == :default ? event[:name] : "#{event[:name]}_#{machine}"
          <<~RUBY.rstrip
            authorize(:#{event[:name]}) { |_record, _context| false }
            transition :#{event[:name]}, from: :#{event[:from]}, to: :#{event[:to]}, attribute: :#{attribute}, via: :#{method_suffix}, guard: :may_#{method_suffix}?
          RUBY
        end

        <<~RUBY
          class #{resource.camelize}Resource
            field :#{attribute}, :state_machine, states: #{states.inspect}#{machine_option}
            #{declarations.join("\n  ")}
          end
        RUBY
      end

      def test
        first_event = events.first
        <<~RUBY
          require "test_helper"

          class #{workflow_module}Test < ActiveSupport::TestCase
            test "defines the configured states and events" do
              record = #{model_class}.new

              assert_equal "#{states.first}", record.#{attribute}.to_s
              assert record.public_send(:may_#{machine == :default ? first_event[:name] : "#{first_event[:name]}_#{machine}"}?)
            end
          end
        RUBY
      end
    end
  end
end