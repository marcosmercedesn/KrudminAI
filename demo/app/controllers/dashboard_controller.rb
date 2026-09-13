class DashboardController < ApplicationController
  before_action :require_sign_in

  def show
    @dashboard = TicketsDashboard.new(context: access_context, params: request.query_parameters)
    @widgets = @dashboard.render
  end

  def refresh
    @dashboard = TicketsDashboard.new(context: access_context, params: request.query_parameters)
    @widgets = @dashboard.render
    render formats: [ :turbo_stream ]
  end
end
