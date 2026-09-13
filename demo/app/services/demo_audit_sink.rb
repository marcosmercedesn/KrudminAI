class DemoAuditSink
  def record(event)
    attributes = event.to_h
    actor = attributes[:actor]

    DemoAuditEvent.create!(
      event_type: event.class.name.demodulize.underscore,
      actor_name: actor.respond_to?(:name) ? actor.name : actor.to_s,
      tenant: attributes.fetch(:tenant).to_s,
      operation: attributes[:operation].to_s,
      record_type: "DemoTicket",
      record_identifier: attributes[:record_id].to_s,
      metadata: attributes.except(:actor, :tenant, :operation, :record_id)
    )
  end
end
