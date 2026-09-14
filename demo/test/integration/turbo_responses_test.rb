require "test_helper"

# Turbo requires 303 after a non-GET redirect and a Turbo-Location header on stream responses,
# so both are asserted per operation rather than through a generic redirect matcher.
class TurboResponsesTest < ActionDispatch::IntegrationTest
  setup do
    DemoAuditEvent.delete_all
    DemoPassenger.delete_all
    DemoTicket.delete_all
    DemoUser.delete_all

    @manager = DemoUser.create!(name: "Avery Patel", tenant: "northwind", roles: [ "manager" ])
    @agent = DemoUser.create!(name: "Morgan Lee", tenant: "northwind", roles: [ "support_agent" ])
    @ticket = DemoTicket.create!(tenant: "northwind", title: "Printer queue", state: "open", priority: "high", assignee: @agent.name)
  end

  test "every successful HTML mutation redirects with see other" do
    sign_in(@manager)

    post tickets_path, params: { demo_ticket: ticket_attributes }
    assert_response :see_other

    patch ticket_path(@ticket), params: { demo_ticket: { priority: "urgent" } }
    assert_response :see_other

    post action_ticket_path(@ticket, action_name: "assign_to_me")
    assert_response :see_other

    delete ticket_path(@ticket)
    assert_response :see_other

    patch restore_ticket_path(@ticket)
    assert_response :see_other
  end

  test "a successful HTML mutation sends destroy and archive back to the collection" do
    sign_in(@manager)

    delete ticket_path(@ticket)
    assert_redirected_to tickets_path

    patch restore_ticket_path(@ticket)
    assert_redirected_to ticket_path(@ticket)
  end

  test "an update answered as a turbo stream replaces the flash and points at the record" do
    sign_in(@manager)

    patch ticket_path(@ticket), params: { demo_ticket: { priority: "urgent" } }, as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_equal ticket_path(@ticket), response.headers.fetch("Turbo-Location")
    assert_includes response.body, "krudmin-ai-flash"
    assert_equal "urgent", @ticket.reload.priority
  end

  test "an archive answered as a turbo stream points at the collection rather than the record" do
    sign_in(@manager)

    delete ticket_path(@ticket), as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_equal tickets_path, response.headers.fetch("Turbo-Location")
    assert @ticket.reload.archived_at
  end

  test "a restore answered as a turbo stream points back at the record" do
    sign_in(@manager)
    delete ticket_path(@ticket)

    patch restore_ticket_path(@ticket), as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_equal ticket_path(@ticket), response.headers.fetch("Turbo-Location")
    assert_nil @ticket.reload.archived_at
  end

  test "a rejected update answered as a turbo stream re-renders the form without a location" do
    sign_in(@manager)

    patch ticket_path(@ticket), params: { demo_ticket: { title: "" } }, as: :turbo_stream

    assert_response :unprocessable_entity
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, "krudmin-ai-resource-form"
    assert_includes response.body, "Title can&#39;t be blank"
    assert_nil response.headers["Turbo-Location"]
    assert_equal "Printer queue", @ticket.reload.title
  end

  test "an inline edit submits to the record and is answered as a turbo stream" do
    sign_in(@manager)

    patch ticket_path(@ticket), params: { demo_ticket: { priority: "low" } }, as: :turbo_stream

    assert_response :success
    assert_equal ticket_path(@ticket), response.headers.fetch("Turbo-Location")
    assert_equal "low", @ticket.reload.priority
  end

  test "a denied mutation answered as a turbo stream reports the failure in the flash" do
    sign_in(@agent)

    delete ticket_path(@ticket), as: :turbo_stream

    assert_response :forbidden
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, "krudmin-ai-flash"
    assert_nil response.headers["Turbo-Location"]
    assert_nil @ticket.reload.archived_at
  end

  test "a bulk action redirects with see other so Turbo does not repeat the post" do
    sign_in(@manager)
    second = DemoTicket.create!(tenant: "northwind", title: "Second queue", state: "assigned", priority: "normal", assignee: @agent.name)

    post bulk_action_tickets_path(action_name: "resolve"), params: { ids: [ @ticket.id, second.id ] }

    assert_response :see_other
    assert_redirected_to tickets_path
    assert_equal %w[resolved resolved], [ @ticket.reload.state, second.reload.state ]
  end

  test "a bulk action refuses a set that reaches outside the tenant" do
    sign_in(@manager)
    foreign = DemoTicket.create!(tenant: "southwind", title: "Foreign", state: "open", priority: "normal", assignee: "Jordan Kim")

    assert_no_difference -> { DemoAuditEvent.count } do
      post bulk_action_tickets_path(action_name: "resolve"), params: { ids: [ @ticket.id, foreign.id ] }
    end

    assert_response :forbidden
    assert_equal "open", @ticket.reload.state
    assert_equal "open", foreign.reload.state
  end

  private

  def sign_in(user)
    post session_path, params: { demo_user_id: user.id }
    assert_redirected_to tickets_path
  end

  def ticket_attributes
    { title: "Turbo ticket", description: "Created for Turbo coverage.", state: "open", priority: "normal", assignee: @agent.name }
  end
end
