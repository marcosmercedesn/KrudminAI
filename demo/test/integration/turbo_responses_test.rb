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

  test "an update answered as a turbo stream redirects unless the form asked to stream" do
    sign_in(@manager)

    patch ticket_path(@ticket), params: { demo_ticket: { priority: "urgent" } }, as: :turbo_stream

    assert_response :see_other
    assert_redirected_to ticket_path(@ticket)
    assert_equal "urgent", @ticket.reload.priority
  end

  test "a form that opts into streaming keeps the browser in place and points at the record" do
    sign_in(@manager)

    patch ticket_path(@ticket), params: { demo_ticket: { priority: "urgent" }, krudmin_ai_stream: "1" }, as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_equal ticket_path(@ticket), response.headers.fetch("Turbo-Location")
    assert_includes response.body, "krudmin-ai-flash"
    assert_equal "urgent", @ticket.reload.priority
  end

  test "an archive that opts into streaming points at the collection rather than the record" do
    sign_in(@manager)

    delete ticket_path(@ticket), params: { krudmin_ai_stream: "1" }, as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_equal tickets_path, response.headers.fetch("Turbo-Location")
    assert @ticket.reload.archived_at
  end

  test "a restore that opts into streaming points back at the record" do
    sign_in(@manager)
    delete ticket_path(@ticket)

    patch restore_ticket_path(@ticket), params: { krudmin_ai_stream: "1" }, as: :turbo_stream

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

  test "an inline edit opts into streaming so the list stays in place" do
    sign_in(@manager)

    get tickets_path
    assert_select "form.krudmin-ai-inline-edit input[name=?][value=?]", "krudmin_ai_stream", "1"

    patch ticket_path(@ticket), params: { demo_ticket: { priority: "low" }, krudmin_ai_stream: "1" }, as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
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

  test "a bulk action answered as a turbo stream redirects unless the form asked to stream" do
    sign_in(@manager)

    post bulk_action_tickets_path(action_name: "resolve"), params: { ids: [ @ticket.id ] }, as: :turbo_stream

    assert_response :see_other
    assert_redirected_to tickets_path
    assert_equal "resolved", @ticket.reload.state
  end

  test "a bulk action that opts into streaming replaces the flash and points at the collection" do
    sign_in(@manager)

    post bulk_action_tickets_path(action_name: "resolve"), params: { ids: [ @ticket.id ], krudmin_ai_stream: "1" }, as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_equal tickets_path, response.headers.fetch("Turbo-Location")
    assert_includes response.body, "krudmin-ai-flash"
    assert_equal "resolved", @ticket.reload.state
  end

  test "a rejected bulk action reports through each format rather than always answering JSON" do
    sign_in(@manager)
    @ticket.update!(state: "resolved")

    post bulk_action_tickets_path(action_name: "resolve"), params: { ids: [ @ticket.id ] }
    assert_response :see_other
    assert_redirected_to tickets_path

    post bulk_action_tickets_path(action_name: "resolve"), params: { ids: [ @ticket.id ] }, as: :turbo_stream
    assert_response :unprocessable_entity
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, "krudmin-ai-flash"

    post bulk_action_tickets_path(action_name: "resolve"), params: { ids: [ @ticket.id ] }, as: :json
    assert_response :unprocessable_entity
    assert_equal "application/json", response.media_type
  end

  test "a bulk action denied outside the tenant answers the requested format" do
    sign_in(@manager)
    foreign = DemoTicket.create!(tenant: "southwind", title: "Foreign", state: "open", priority: "normal", assignee: "Jordan Kim")

    post bulk_action_tickets_path(action_name: "resolve"), params: { ids: [ @ticket.id, foreign.id ] }, as: :turbo_stream

    assert_response :forbidden
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, "krudmin-ai-flash"
  end

  test "a bulk action button carries its variant class and confirmation" do
    sign_in(@manager)

    get tickets_path

    assert_select "form#krudmin-ai-bulk-actions button.krudmin-ai-button", text: "Resolve"
    assert_select "button[class*='krudmin-ai-button#']", 0
  end

  test "a confirmation is declared only for the actions that ask for one" do
    sign_in(@manager)

    get ticket_path(@ticket)

    assert_select "button[data-turbo-confirm=?]", "Assign this ticket to yourself?", text: "Assign to me"
    assert_select "button[data-turbo-confirm]", { count: 1 }, "Only a declared confirmation should emit the attribute"
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
