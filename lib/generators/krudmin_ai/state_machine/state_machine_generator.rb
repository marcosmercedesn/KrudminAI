require "rails/generators"
require "krudmin_ai/generators/state_machine_contract"

module KrudminAI
  module Generators
    class StateMachineGenerator < Rails::Generators::NamedBase
      namespace "krudmin_ai:state_machine"
      class_option :resource, type: :string, desc: "Resource model name; defaults to NAME"
      class_option :attribute, type: :string, default: "status", desc: "State column name"
      class_option :machine, type: :string, default: "default", desc: "AASM machine name"
      class_option :states, type: :array, default: StateMachineContract::DEFAULT_STATES, desc: "Ordered workflow states"
      class_option :events, type: :array, default: StateMachineContract::DEFAULT_EVENTS, desc: "Events as name:from:to"

      def install_state_machine
        StateMachineContract.new(
          destination_root:,
          name:,
          resource: options[:resource],
          attribute: options[:attribute],
          machine: options[:machine],
          states: options[:states],
          events: options[:events]
        ).install
      end
    end
  end
end