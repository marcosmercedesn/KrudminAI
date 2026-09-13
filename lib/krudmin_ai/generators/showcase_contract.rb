require "json"
require "krudmin_ai/generators/file_writer"
require "krudmin_ai/generators/host_manifest"

module KrudminAI
  module Generators
    class ShowcaseContract
      ROUTES_MARKER = "KRUDMIN_AI_SHOWCASE_ROUTES".freeze

      def initialize(destination_root:, source_root:, mode: "full")
        @writer = FileWriter.new(destination_root)
        @source_root = source_root
        @mode = mode.to_s
      end

      def install
        raise ArgumentError, "Unsupported showcase mode: #{mode}" unless %w[lightweight full].include?(mode)

        files.each { |path, contents| writer.create(path, contents) }
        writer.replace_managed_block("config/routes.rb", marker: ROUTES_MARKER, contents: routes, inside_routes: true)
        manifest.enable("showcase_#{mode}")
      end

      private

      attr_reader :writer, :source_root, :mode

      def manifest
        @manifest ||= HostManifest.new(writer)
      end

      def files
        {
          "db/migrate/20260912000000_create_krudmin_ai_showcase_tickets.rb" => migration,
          "app/models/krudmin_ai_showcase/ticket.rb" => ticket_model,
          "app/resources/showcase_tickets_resource.rb" => resource,
          "app/controllers/admin/showcase_tickets_controller.rb" => controller,
          "app/policies/krudmin_ai_showcase/ticket_policy.rb" => policy,
          "db/seeds/krudmin_ai_showcase.rb" => seeds,
          "docs/krudmin_ai_showcase.md" => source("docs/showcase.md"),
          "docs/krudmin_ai_showcase_agent_playbook.md" => source("docs/showcase_agent_playbook.md"),
          ".krudmin_ai/showcase_manifest.json" => showcase_manifest
        }.merge(full_files)
      end

      def full_files
        return {} unless mode == "full"

        {
          "app/dashboards/krudmin_ai_showcase/tickets_dashboard.rb" => dashboard,
          "test/integration/krudmin_ai_showcase_test.rb" => scenario_test
        }
      end

      def source(path)
        File.read(File.join(source_root, path))
      end

      def ticket_model
        <<~RUBY
          module KrudminAIShowcase
              class Ticket < ApplicationRecord
              self.table_name = "krudmin_ai_showcase_tickets"

              STATES = %w[open assigned resolved].freeze
              validates :tenant, :title, :state, presence: true

              def assign_to!(actor)
                update!(assignee: actor, state: "assigned")
              end

              def resolve!
                update!(state: "resolved")
              end
            end
          end
        RUBY
      end

      def migration
        <<~RUBY
          class CreateKrudminAIShowcaseTickets < ActiveRecord::Migration[8.1]
            def change
              create_table :krudmin_ai_showcase_tickets do |table|
                table.string :tenant, null: false
                table.string :title, null: false
                table.string :state, null: false
                table.string :priority, null: false
                table.string :assignee
                table.timestamps
              end
              add_index :krudmin_ai_showcase_tickets, [:tenant, :state]
            end
          end
        RUBY
      end

      def resource
        <<~RUBY
          class ShowcaseTicketsResource < KrudminAI::Resources::Base
              model KrudminAIShowcase::Ticket
            routes :showcase_tickets
            tenant_key :tenant
            icon :ticket
            label "showcase ticket"
            plural_label "showcase tickets"
            permit :title, :state, :priority, :assignee
            list :title, :state, :priority, :assignee
            form :title, :state, :priority, :assignee
            show :title, :state, :priority, :assignee

            %i[title state priority assignee].each do |field|
              authorize_field field, read: ->(_record, _context) { true }, write: ->(_record, _context) { true }
            end

            tenant_scope { |relation, context| relation.where(tenant: context.tenant) }
              policy_scope { |relation, context| KrudminAIShowcase::TicketPolicy::Scope.new(context.actor, relation).resolve }
            tenant_record { |record, context| record.tenant == context.tenant }
            filter(:state) { |relation, value, _context| relation.where(state: value) }
            filter(:assignee) { |relation, value, _context| relation.where(assignee: value) }
            sortable :created_at, :state, :priority
            default_sort_by :created_at, direction: :desc

              authorize(:create) { |record, context| KrudminAIShowcase::TicketPolicy.new(context.actor, record).create? }
              authorize(:update) { |record, context| KrudminAIShowcase::TicketPolicy.new(context.actor, record).update? }
              authorize(:destroy) { |record, context| KrudminAIShowcase::TicketPolicy.new(context.actor, record).destroy? }
              authorize(:assign_to_me) { |record, context| KrudminAIShowcase::TicketPolicy.new(context.actor, record).assign_to_me? }
              authorize(:resolve) { |record, context| KrudminAIShowcase::TicketPolicy.new(context.actor, record).resolve? }

            action :assign_to_me, label: "Assign to me", writes: [:assignee] do |record, context|
              record.assignee = context.actor.name
              true
            end
            transition :resolve, from: %i[open assigned], to: :resolved, label: "Resolve"
          end
        RUBY
      end

      def controller
        <<~RUBY
          module Admin
            class ShowcaseTicketsController < KrudminAI::ResourceController
              resource ShowcaseTicketsResource
            end
          end
        RUBY
      end

      def dashboard
        <<~RUBY
          module KrudminAIShowcase
            class TicketsDashboard < KrudminAI::Dashboards::Base
              label "Support operations"

              widget :open_tickets,
                widget_class: KrudminAI::Dashboards::Widgets::Count,
                resource: ShowcaseTicketsResource,
                relation: ->(_context) { Ticket.all },
                visible: ->(_context) { true },
                query_params: { filters: { state: "open" } },
                drill_down_filters: { state: "open" }
              widget :recent_tickets,
                widget_class: KrudminAI::Dashboards::Widgets::Table,
                resource: ShowcaseTicketsResource,
                relation: ->(_context) { Ticket.all },
                visible: ->(_context) { true },
                columns: %i[title state priority],
                limit: 10
            end
          end
        RUBY
      end

      def policy
        <<~RUBY
          module KrudminAIShowcase
            class TicketPolicy
              attr_reader :user, :record

              def initialize(user, record)
                @user = user
                @record = record
              end

              def create? = support_agent?
              def update? = support_agent? && same_tenant?
              def destroy? = manager? && same_tenant?
              def assign_to_me? = support_agent? && same_tenant?
              def resolve? = manager? && same_tenant?

              class Scope
                attr_reader :user, :scope

                def initialize(user, scope)
                  @user = user
                  @scope = scope
                end

                def resolve
                  scope.where(tenant: user.tenant)
                end
              end

              private

              def support_agent? = Array(user&.roles).map(&:to_sym).include?(:support_agent)
              def manager? = Array(user&.roles).map(&:to_sym).include?(:manager)
              def same_tenant? = user && record.tenant == user.tenant
            end
          end
        RUBY
      end

      def seeds
        <<~RUBY
          north = "northwind"
          south = "southwind"

            KrudminAIShowcase::Ticket.find_or_create_by!(tenant: north, title: "Unable to export monthly orders") do |ticket|
            ticket.state = "open"
            ticket.priority = "high"
            ticket.assignee = "morgan"
          end
            KrudminAIShowcase::Ticket.find_or_create_by!(tenant: north, title: "Update billing address") do |ticket|
            ticket.state = "assigned"
            ticket.priority = "normal"
            ticket.assignee = "avery"
          end
            KrudminAIShowcase::Ticket.find_or_create_by!(tenant: south, title: "Inventory count is delayed") do |ticket|
            ticket.state = "open"
            ticket.priority = "high"
            ticket.assignee = "jordan"
          end
        RUBY
      end

      def scenario_test
        <<~RUBY
          require "test_helper"

          class KrudminAIShowcaseTest < ActionDispatch::IntegrationTest
            setup do
              KrudminAIShowcase::Ticket.delete_all
              DemoAuditEvent.delete_all
              register_showcase_navigation
              @north_agent = DemoUser.find_or_create_by!(name: "Showcase North Agent", tenant: "northwind") { |user| user.roles = ["support_agent"] }
              @north_manager = DemoUser.find_or_create_by!(name: "Showcase North Manager", tenant: "northwind") { |user| user.roles = ["manager"] }
              @south_agent = DemoUser.find_or_create_by!(name: "Showcase South Agent", tenant: "southwind") { |user| user.roles = ["support_agent"] }
              @north_ticket = KrudminAIShowcase::Ticket.create!(tenant: "northwind", title: "North queue", state: "open", priority: "high")
              @south_ticket = KrudminAIShowcase::Ticket.create!(tenant: "southwind", title: "South queue", state: "open", priority: "urgent")
            end

            test "requires authentication and scopes tenant workflow data" do
              get admin_showcase_tickets_path
              assert_redirected_to new_session_path

              sign_in(@north_agent)
              get admin_showcase_tickets_path, params: { filters: { state: "open" } }
              assert_response :success
              assert_includes response.body, "krudmin-ai-shell"
              assert_includes response.body, "krudmin-ai-navigation"
              assert_includes response.body, "krudmin-ai-theme"
              assert_includes response.body, "Showcase tickets"
              assert_includes response.body, @north_ticket.title
              assert_not_includes response.body, @south_ticket.title

              assert_difference -> { DemoAuditEvent.count }, 1 do
                post action_admin_showcase_ticket_path(@north_ticket, action_name: "assign_to_me")
              end
              assert_equal @north_agent.name, @north_ticket.reload.assignee

              post action_admin_showcase_ticket_path(@south_ticket, action_name: "assign_to_me")
              assert_response :not_found
            end

            test "manager transitions and dashboard remain tenant scoped" do
              sign_in(@north_manager)
              post action_admin_showcase_ticket_path(@north_ticket, action_name: "resolve")
              assert_response :redirect
              assert_equal "resolved", @north_ticket.reload.state

              context = KrudminAI::AccessContext.new(actor: @north_manager, tenant: "northwind", roles: @north_manager.roles)
              widgets = KrudminAIShowcase::TicketsDashboard.new(context:).render
              rows = widgets.find { |widget| widget.name == :recent_tickets }.rows
              assert rows.all? { |row| row[:title] != @south_ticket.title }
            end

            private

            def register_showcase_navigation
              return if KrudminAI.config.navigation_items.any? { |item| item.display_label == "Showcase tickets" }

              KrudminAI.config.navigation_item(
                label: "Showcase tickets",
                route: ->(view) { view.main_app.admin_showcase_tickets_path },
                icon: :ticket,
                visible: ->(context) { context.roles.map(&:to_sym).include?(:support_agent) || context.roles.map(&:to_sym).include?(:manager) }
              )
            end

            def sign_in(user)
              post session_path, params: { demo_user_id: user.id }
            end
          end
        RUBY
      end

      def routes
        <<~RUBY.rstrip
          namespace :admin do
            resources :showcase_tickets do
              post "actions/:action_name", on: :member, to: "showcase_tickets#perform_action", as: :action
            end
          end
        RUBY
      end

      def showcase_manifest
        JSON.pretty_generate(
          "name" => "support_operations",
          "mode" => mode,
          "engine_version" => KrudminAI::VERSION,
          "required_capabilities" => mode == "full" ? %w[resource_query_pipeline crud_mutation_pipeline hotwire_ui_foundations dashboard_lifecycle_and_drill_downs] : %w[resource_query_pipeline crud_mutation_pipeline hotwire_ui_foundations],
          "demonstrations" => {
            "crud" => "ShowcaseTicketsResource and generic resource controller",
            "search_and_filtering" => "state and assignee filters",
            "tenant_and_role_access" => "two tenant, support-agent and manager scenarios",
            "custom_actions" => "declared assign_to_me action",
            "state_transitions" => "declared resolve transition",
            "dashboard_summaries" => "Dashboards::Base count and table widgets",
            "audit_trail_hooks" => "MutationPipeline audit sink for ticket mutations",
            "themes" => "host theme controller"
          },
          "required_documents" => %w[docs/krudmin_ai_showcase.md docs/krudmin_ai_showcase_agent_playbook.md]
        ) + "\n"
      end
    end
  end
end
