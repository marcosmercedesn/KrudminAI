class DashboardController < ApplicationController
  before_action :require_sign_in

  def show
    pipeline = KrudminAI::QueryAccessPipeline.new(resource: TicketsResource, context: access_context)
    @tickets = pipeline.authorized_relation(DemoTicket.all)
    @open_count = @tickets.where(state: "open").count
    @assigned_count = @tickets.where(state: "assigned").count
    @recent_tickets = pipeline.call(DemoTicket.all).records.first(5)
    @audit_events = DemoAuditEvent.where(tenant: current_tenant).order(created_at: :desc).limit(6)
  end
end