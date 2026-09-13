class CompanionController < ApplicationController
  before_action :require_sign_in

  def show; end

  def create
    @result = KrudminAI::Ai::Assistant.new(
      context: access_context,
      provider: DemoCompanionProvider.new,
      provider_name: "demo-local-summary",
      tracer: DemoCompanionTraceSink.new(current_user)
    ).call(
      task: :report_insight,
      resource: TicketsResource,
      relation: DemoTicket.all,
      prompt_template: "demo_companion_v1",
      input: { prompt: params[:prompt].to_s },
      params: { filters: params[:filters].to_h }
    )

    render :show
  end
end
