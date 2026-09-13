class DemoCompanionTraceSink
  def initialize(user)
    @user = user
  end

  def record(trace)
    DemoAuditEvent.create!(
      event_type: "ai_trace",
      actor_name: user.name,
      tenant: user.tenant,
      operation: "read_only",
      record_type: "AiTrace",
      record_identifier: trace.scoped_context_fingerprint,
      metadata: trace.to_h.except(:actor, :scoped_context_fingerprint)
    )
  end

  private

  attr_reader :user
end
