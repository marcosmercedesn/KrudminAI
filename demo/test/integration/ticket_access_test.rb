require "test_helper"

class TicketAccessTest < ActionDispatch::IntegrationTest
  setup do
    DemoAuditEvent.delete_all
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
end