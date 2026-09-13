class TicketsDashboard < KrudminAI::Dashboards::Base
  label "Workspace overview"

  widget :visible_tickets,
    widget_class: KrudminAI::Dashboards::Widgets::Count,
    resource: TicketsResource,
    relation: ->(_context) { DemoTicket.all },
    visible: ->(_context) { true },
    label: "Visible tickets",
    drill_down_filters: {}
  widget :open_queue,
    widget_class: KrudminAI::Dashboards::Widgets::Count,
    resource: TicketsResource,
    relation: ->(_context) { DemoTicket.all },
    visible: ->(_context) { true },
    label: "Open queue",
    query_params: { filters: { state: "open" } },
    drill_down_filters: { state: "open" }
  widget :recent_tickets,
    widget_class: KrudminAI::Dashboards::Widgets::Table,
    resource: TicketsResource,
    relation: ->(_context) { DemoTicket.all },
    visible: ->(_context) { true },
    label: "Recent tickets",
    columns: %i[title state priority assignee],
    limit: 5,
    drill_down_filters: {}
  widget :manager_queue,
    widget_class: KrudminAI::Dashboards::Widgets::Count,
    resource: TicketsResource,
    relation: ->(_context) { DemoTicket.all },
    visible: ->(context) { context.roles.include?(:manager) },
    label: "Manager queue",
    query_params: { filters: { state: "assigned" } },
    drill_down_filters: { state: "assigned" }
end
