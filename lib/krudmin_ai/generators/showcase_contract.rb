require "json"
require "krudmin_ai/generators/file_writer"

module KrudminAI
  module Generators
    class ShowcaseContract
      ROUTES_MARKER = "KRUDMIN_AI_SHOWCASE_ROUTES".freeze

      def initialize(destination_root:, source_root:)
        @writer = FileWriter.new(destination_root)
        @source_root = source_root
      end

      def install
        files.each { |path, contents| writer.create(path, contents) }
        writer.replace_managed_block("config/routes.rb", marker: ROUTES_MARKER, contents: routes)
      end

      private

      attr_reader :writer, :source_root

      def files
        {
          "db/migrate/20260912000000_create_krudmin_ai_showcase_tickets.rb" => migration,
          "app/models/krudmin_ai_showcase/ticket.rb" => ticket_model,
          "app/resources/showcase_tickets_resource.rb" => resource,
          "app/controllers/admin/showcase_tickets_controller.rb" => controller,
          "app/services/krudmin_ai_showcase/ticket_workflow.rb" => workflow,
          "app/policies/krudmin_ai_showcase/ticket_policy.rb" => policy,
          "app/dashboards/krudmin_ai_showcase/tickets_dashboard.rb" => dashboard,
          "db/seeds/krudmin_ai_showcase.rb" => seeds,
          "spec/requests/admin/showcase_tickets_spec.rb" => request_spec,
          "docs/krudmin_ai_showcase.md" => source("docs/showcase.md"),
          "docs/krudmin_ai_showcase_agent_playbook.md" => source("docs/showcase_agent_playbook.md"),
          ".krudmin_ai/showcase_manifest.json" => source("showcase/manifest.json")
        }
      end

      def source(path)
        File.read(File.join(source_root, path))
      end

      def ticket_model
        <<~RUBY
          module KrudminAiShowcase
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
          class CreateKrudminAiShowcaseTickets < ActiveRecord::Migration[8.1]
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
            model KrudminAiShowcase::Ticket

            tenant_scope { |relation, context| relation.where(tenant: context.tenant) }
            policy_scope { |relation, context| KrudminAiShowcase::TicketPolicy::Scope.new(context.actor, relation).resolve }
            tenant_record { |record, context| record.tenant == context.tenant }
            filter(:state) { |relation, value, _context| relation.where(state: value) }
            filter(:assignee) { |relation, value, _context| relation.where(assignee: value) }
            sortable :created_at, :state, :priority
            default_sort_by :created_at, direction: :desc

            authorize(:create) { |record, context| KrudminAiShowcase::TicketPolicy.new(context.actor, record).create? }
            authorize(:update) { |record, context| KrudminAiShowcase::TicketPolicy.new(context.actor, record).update? }
            authorize(:destroy) { |record, context| KrudminAiShowcase::TicketPolicy.new(context.actor, record).destroy? }
          end
        RUBY
      end

      def controller
        <<~RUBY
          module Admin
            class ShowcaseTicketsController < ApplicationController
              before_action :authenticate_user!

              def assign_to_me
                respond_with_mutation(workflow.assign_to_me(ticket))
              end

              def resolve
                respond_with_mutation(workflow.resolve(ticket))
              end

              private

              def ticket
                KrudminAiShowcase::Ticket.find(params[:id])
              end

              def workflow
                KrudminAiShowcase::TicketWorkflow.new(
                  context: KrudminAI::AccessContext.new(actor: current_user, tenant: current_tenant, roles: current_user.roles),
                  auditor: KrudminAI.config.audit_provider
                )
              end

              def respond_with_mutation(result)
                response = KrudminAI::MutationResponseAdapter.for(result, format: request.format.symbol)
                render response.payload, status: response.status
              end
            end
          end
        RUBY
      end

      def workflow
        <<~RUBY
          module KrudminAiShowcase
            class TicketWorkflow
              def initialize(context:, auditor:)
                @context = context
                @auditor = auditor
              end

              def assign_to_me(ticket)
                run(ticket, :assign_to_me?, assignee: context.actor, state: "assigned")
              end

              def resolve(ticket)
                run(ticket, :resolve?, state: "resolved")
              end

              private

              attr_reader :context, :auditor

              def run(ticket, predicate, attributes)
                raise KrudminAI::AuthorizationDenied unless TicketPolicy.new(context.actor, ticket).public_send(predicate)

                KrudminAI::MutationPipeline.new(resource: ShowcaseTicketsResource, context:, auditor:)
                  .call(operation: :update, record: ticket, attributes:)
              end
            end
          end
        RUBY
      end

      def dashboard
        <<~RUBY
          module KrudminAiShowcase
            class TicketsDashboard
              def initialize(context:)
                @context = context
              end

              def widgets
                [
                  KrudminAI::Dashboards::Widgets::Count.new(resource:, context:, relation: relation),
                  KrudminAI::Dashboards::Widgets::Table.new(resource:, context:, relation: relation, columns: %i[title state priority], limit: 10),
                  KrudminAI::Dashboards::Widgets::Summary.new(resource:, context:, relation: relation, summarize: ->(scope) { { open_tickets: scope.where(state: "open").count } })
                ]
              end

              private

              attr_reader :context

              def resource = ShowcaseTicketsResource
              def relation = Ticket.all
            end
          end
        RUBY
      end

      def policy
        <<~RUBY
          module KrudminAiShowcase
            class TicketPolicy < ApplicationPolicy
              def create? = support_agent?
              def update? = support_agent? && record.tenant == user.current_tenant
              def destroy? = manager? && record.tenant == user.current_tenant
              def assign_to_me? = support_agent? && record.tenant == user.current_tenant
              def resolve? = manager? && record.tenant == user.current_tenant

              class Scope < ApplicationPolicy::Scope
                def resolve
                  scope.where(tenant: user.current_tenant)
                end
              end

              private

              def support_agent? = user.roles.include?(:support_agent)
              def manager? = user.roles.include?(:manager)
            end
          end
        RUBY
      end

      def seeds
        <<~RUBY
          north = "northwind"
          south = "southwind"

          KrudminAiShowcase::Ticket.find_or_create_by!(tenant: north, title: "Unable to export monthly orders") do |ticket|
            ticket.state = "open"
            ticket.priority = "high"
            ticket.assignee = "morgan"
          end
          KrudminAiShowcase::Ticket.find_or_create_by!(tenant: north, title: "Update billing address") do |ticket|
            ticket.state = "assigned"
            ticket.priority = "normal"
            ticket.assignee = "avery"
          end
          KrudminAiShowcase::Ticket.find_or_create_by!(tenant: south, title: "Inventory count is delayed") do |ticket|
            ticket.state = "open"
            ticket.priority = "high"
            ticket.assignee = "jordan"
          end
        RUBY
      end

      def request_spec
        <<~RUBY
          require "rails_helper"

          RSpec.describe "showcase tickets", type: :request do
            it "requires authentication" do
              get admin_showcase_tickets_path
              expect(response).to have_http_status(:unauthorized)
            end
          end
        RUBY
      end

      def routes
        <<~RUBY.rstrip
          namespace :admin do
            resources :showcase_tickets do
              member do
                patch :assign_to_me
                patch :resolve
              end
            end
          end
        RUBY
      end
    end
  end
end