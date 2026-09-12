class DemoCompanionProvider
  def call(request)
    tickets = request.context
    states = tickets.group_by { |ticket| ticket[:state] }.transform_values(&:count)
    priorities = tickets.group_by { |ticket| ticket[:priority] }.transform_values(&:count)
    plural = tickets.size == 1 ? "ticket" : "tickets"
    response = [
      "I reviewed #{tickets.size} #{plural} available to your current tenant.",
      "States: #{summary(states)}.",
      "Priority mix: #{summary(priorities)}.",
      "Your question: #{request.input.fetch(:prompt, "No question supplied")}"
    ].join(" ")

    { output: response, tool_calls: [], action_references: [] }
  end

  private

  def summary(values)
    values.map { |name, count| "#{name} #{count}" }.join(", ").presence || "none"
  end
end