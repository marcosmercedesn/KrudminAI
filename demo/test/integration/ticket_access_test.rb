require "test_helper"

class TicketAccessTest < ActionDispatch::IntegrationTest
  setup do
    DemoAuditEvent.delete_all
    DemoPassenger.delete_all
    DemoTicket.delete_all
    DemoUser.delete_all

    @north_agent = DemoUser.create!(name: "Morgan Lee", tenant: "northwind", roles: ["support_agent"])
    @north_manager = DemoUser.create!(name: "Avery Patel", tenant: "northwind", roles: ["manager"])
    @south_agent = DemoUser.create!(name: "Jordan Kim", tenant: "southwind", roles: ["support_agent"])
    @north_ticket = DemoTicket.create!(tenant: "northwind", title: "Northwind export", state: "open", priority: "high", assignee: @north_agent.name)
    @south_ticket = DemoTicket.create!(tenant: "southwind", title: "Southwind inventory", state: "open", priority: "urgent", assignee: @south_agent.name)
  end

  test "anonymous users are sent to the demo sign in screen" do
    get tickets_path

    assert_redirected_to new_session_path
  end

  test "support agents see only their tenant tickets and can render the dashboard" do
    sign_in(@north_agent)

    get tickets_path

    assert_response :success
    assert_includes response.body, @north_ticket.title
    assert_not_includes response.body, @south_ticket.title

    get dashboard_path

    assert_response :success
    assert_includes response.body, "Workspace overview"
    assert_includes response.body, @north_ticket.title
    assert_not_includes response.body, @south_ticket.title
  end

  test "cross tenant tickets are not reachable" do
    sign_in(@north_agent)

    get ticket_path(@south_ticket)

    assert_response :not_found
  end

  test "support agents can render and submit the new ticket form with an audit event" do
    sign_in(@north_agent)

    get new_ticket_path

    assert_response :success
    assert_includes response.body, "New ticket"

    assert_difference -> { DemoTicket.count }, 1 do
      assert_difference -> { DemoAuditEvent.count }, 1 do
        post tickets_path, params: {
          demo_ticket: {
            title: "New Northwind ticket",
            description: "Created by the integration test.",
            state: "open",
            priority: "normal",
            assignee: @north_agent.name
          }
        }
      end
    end

    ticket = DemoTicket.order(:created_at).last
    assert_redirected_to ticket_path(ticket)
    assert_equal "northwind", ticket.tenant
    assert_equal "create", DemoAuditEvent.order(:created_at).last.operation
  end

  test "JSON mutation responses use the normalized success and error envelope" do
    sign_in(@north_agent)

    post tickets_path, params: { demo_ticket: ticket_attributes }, as: :json

    assert_response :created
    assert_equal "success", JSON.parse(response.body).fetch("outcome")
    assert_equal "Nested Northwind ticket", JSON.parse(response.body).fetch("data").fetch("title")

    post tickets_path, params: { demo_ticket: ticket_attributes.merge(title: "") }, as: :json

    assert_response :unprocessable_entity
    error_response = JSON.parse(response.body)
    assert_nil error_response.fetch("data")
    assert_equal "invalid", error_response.fetch("outcome")
    assert_equal "invalid", error_response.fetch("errors").first.fetch("code")

    patch ticket_path(@south_ticket), params: { demo_ticket: { title: "Leaked" } }, as: :json

    assert_response :not_found
    assert_not_includes response.body, @south_ticket.title
  end

  test "Turbo Stream mutation responses use success and validation templates" do
    sign_in(@north_agent)

    post tickets_path, params: { demo_ticket: ticket_attributes }, as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_equal ticket_path(DemoTicket.order(:created_at).last), response.headers.fetch("Turbo-Location")
    assert_includes response.body, "krudmin-ai-flash"

    post tickets_path, params: { demo_ticket: ticket_attributes.merge(title: "") }, as: :turbo_stream

    assert_response :unprocessable_entity
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, "krudmin-ai-resource-form"
    assert_includes response.body, "Title can&#39;t be blank"
  end

  test "audit failure rolls back a mutation before returning an error" do
    sign_in(@north_agent)
    original_audit_provider = KrudminAI.config.audit_provider
    KrudminAI.config.audit_provider = Class.new do
      def record(event)
        raise "audit unavailable"
      end
    end.new

    assert_no_difference -> { DemoTicket.count } do
      assert_no_difference -> { DemoAuditEvent.count } do
        post tickets_path, params: { demo_ticket: ticket_attributes }
      end
    end

    assert_response :internal_server_error
  ensure
    KrudminAI.config.audit_provider = original_audit_provider

    if original_audit_provider
      assert_difference -> { DemoTicket.count }, 1 do
        assert_difference -> { DemoAuditEvent.count }, 1 do
          post tickets_path, params: { demo_ticket: ticket_attributes }
        end
      end
    end
  end

  test "support agents create a ticket with authorized passengers in one submission" do
    sign_in(@north_agent)

    assert_difference -> { DemoTicket.count }, 1 do
      assert_difference -> { DemoPassenger.count }, 2 do
        post tickets_path, params: { demo_ticket: ticket_attributes.merge(passengers_attributes: {
          "0" => { name: "Samira Chen", position: 1 },
          "1" => { name: "Diego Ruiz", position: 2 }
        }) }
      end
    end

    ticket = DemoTicket.order(:created_at).last
    assert_redirected_to ticket_path(ticket)
    assert_equal ["Diego Ruiz", "Samira Chen"], ticket.passengers.order(:name).pluck(:name)
    assert_equal ["northwind"], ticket.passengers.distinct.pluck(:tenant)
    assert_equal ticket.passengers.pluck(:id).sort, DemoAuditEvent.order(:created_at).last.metadata[:affected_child_references][:passengers].sort
  end

  test "invalid nested passengers retain submitted rows and leave no partial mutation" do
    sign_in(@north_agent)

    assert_no_difference -> { DemoTicket.count } do
      assert_no_difference -> { DemoPassenger.count } do
        post tickets_path, params: { demo_ticket: ticket_attributes.merge(passengers_attributes: {
          "0" => { name: "", position: 1 },
          "1" => { name: "Retained row", position: 2 }
        }) }
      end
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "Name can&#39;t be blank"
    assert_includes response.body, "Retained row"
    assert_select "input[name='demo_ticket[passengers_attributes][0][name]']"
    assert_select "input[name='demo_ticket[passengers_attributes][1][name]']"
  end

  test "authorized updates add and remove passengers atomically" do
    existing = @north_ticket.passengers.create!(tenant: "northwind", name: "Remove me", position: 1)
    sign_in(@north_agent)

    assert_no_difference -> { DemoPassenger.count } do
      patch ticket_path(@north_ticket), params: {
        demo_ticket: {
          passengers_attributes: {
            "0" => { id: existing.id, _destroy: "1" },
            "1" => { name: "Added passenger", position: 2 }
          }
        }
      }
    end

    assert_redirected_to ticket_path(@north_ticket)
    assert_equal ["Added passenger"], @north_ticket.passengers.reload.pluck(:name)
    assert_equal "update", DemoAuditEvent.order(:created_at).last.operation
    assert_includes DemoAuditEvent.order(:created_at).last.metadata[:affected_child_references][:passengers], existing.id.to_s
  end

  test "crafted cross-tenant passenger identifiers fail closed without mutation" do
    foreign_passenger = @south_ticket.passengers.create!(tenant: "southwind", name: "Outside tenant", position: 1)
    sign_in(@north_agent)

    assert_no_difference -> { DemoAuditEvent.count } do
      patch ticket_path(@north_ticket), params: {
        demo_ticket: {
          title: "Attempted overwrite",
          passengers_attributes: { "0" => { id: foreign_passenger.id, name: "Overwritten" } }
        }
      }
    end

    assert_response :forbidden
    assert_equal "Northwind export", @north_ticket.reload.title
    assert_equal "Outside tenant", foreign_passenger.reload.name
  end

  test "empty results and invalid ticket submissions render accessible operational states" do
    sign_in(@north_agent)

    get tickets_path, params: { filters: { state: "resolved" } }

    assert_response :success
    assert_includes response.body, "No tickets found"
    assert_includes response.body, "Create ticket"

    post tickets_path, params: {
      demo_ticket: {
        title: "",
        description: "Missing title.",
        state: "open",
        priority: "normal",
        assignee: @north_agent.name
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "Ticket could not be saved"
    assert_select ".validation-summary li", "Title can't be blank"
    assert_includes response.body, "aria-invalid=\"true\""
  end

  test "support agents can render and submit the edit ticket form with an audit event" do
    sign_in(@north_agent)

    get edit_ticket_path(@north_ticket)

    assert_response :success
    assert_select "header.site-header"
    assert_select "link[href*='app'][data-turbo-track='reload']"
    assert_includes response.body, "Edit ticket"
    assert_includes response.body, ticket_path(@north_ticket)

    assert_difference -> { DemoAuditEvent.count }, 1 do
      patch ticket_path(@north_ticket), params: {
        demo_ticket: {
          title: "Updated Northwind export",
          description: @north_ticket.description,
          state: "assigned",
          priority: "normal",
          assignee: @north_agent.name
        }
      }
    end

    assert_redirected_to ticket_path(@north_ticket)
    assert_equal "Updated Northwind export", @north_ticket.reload.title
    assert_equal "update", DemoAuditEvent.order(:created_at).last.operation
  end

  test "the local companion is read-only, tenant-scoped, and traced" do
    sign_in(@north_agent)

    post companion_path, params: { prompt: "Which ticket should we address first?" }

    assert_response :success
    assert_includes response.body, "I reviewed 1 ticket available to your current tenant."
    assert_equal "ai_trace", DemoAuditEvent.order(:created_at).last.event_type
    assert_equal "northwind", DemoAuditEvent.order(:created_at).last.tenant
  end

  test "managers can delete a tenant ticket and record the mutation" do
    sign_in(@north_manager)

    assert_difference -> { DemoTicket.count }, -1 do
      assert_difference -> { DemoAuditEvent.count }, 1 do
        delete ticket_path(@north_ticket)
      end
    end

    assert_redirected_to tickets_path
    assert_equal "destroy", DemoAuditEvent.order(:created_at).last.operation
  end

  private

  def sign_in(user)
    post session_path, params: { demo_user_id: user.id }
    assert_redirected_to tickets_path
  end

  def ticket_attributes
    {
      title: "Nested Northwind ticket",
      description: "Created with passengers.",
      state: "open",
      priority: "normal",
      assignee: @north_agent.name
    }
  end
end