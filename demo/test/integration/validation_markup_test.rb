require "test_helper"

class ValidationMarkupTest < ActionDispatch::IntegrationTest
  setup do
    DemoAuditEvent.delete_all
    DemoPassenger.delete_all
    DemoTicket.delete_all
    DemoUser.delete_all

    @agent = DemoUser.create!(name: "Morgan Lee", tenant: "northwind", roles: [ "support_agent" ])
    sign_in(@agent)
  end

  test "a writable field renders native constraints, a rule payload, and a stable error node" do
    get new_ticket_path

    assert_response :success
    assert_select "input#demo_ticket_title[required][aria-required=?]", "true"
    assert_select "input#demo_ticket_title[aria-describedby=?]", "demo_ticket_title_error"
    assert_select "p#demo_ticket_title_error.krudmin-ai-field-error[hidden]"
    assert_select "div.krudmin-ai-field[data-krudmin-ai-validation-field=?]", "title" do |fields|
      rules = JSON.parse(fields.first["data-krudmin-ai-validation-rules"])
      assert rules["required"]
      assert_equal "Title can't be blank", rules.dig("messages", "required")
    end
  end

  test "a projected inclusion set reaches the client without leaking server-only rules" do
    get new_ticket_path

    assert_select "div.krudmin-ai-field[data-krudmin-ai-validation-field=?]", "state" do |fields|
      rules = JSON.parse(fields.first["data-krudmin-ai-validation-rules"])
      assert_equal DemoTicket::STATES, rules["one_of"]
      assert rules["required"]
    end
  end

  test "the validation summary is a persistent live region that stays hidden without errors" do
    get new_ticket_path

    assert_select "form[data-controller~=?]", "krudmin-ai-form-validation"
    assert_select "form.krudmin-ai-form-grid[novalidate]", 0
    assert_select "label[for=?]", "demo_ticket_title"
    assert_select "section.krudmin-ai-validation-summary[role=alert][hidden][data-krudmin-ai-form-validation-target=?]", "summary"
    assert_select "ul[data-krudmin-ai-form-validation-target=?]", "summaryList"
    assert_select "section.krudmin-ai-validation-summary ul li", 0
  end

  test "a rejected submission still renders server errors inline and in an anchored summary" do
    post tickets_path, params: { demo_ticket: { title: "", description: "", state: "open", priority: "normal", assignee: @agent.name } }

    assert_response :unprocessable_entity
    assert_select "section.krudmin-ai-validation-summary[role=alert]"
    assert_select "section.krudmin-ai-validation-summary[hidden]", 0
    assert_select "section.krudmin-ai-validation-summary ul li a[href=?]", "#demo_ticket_title", text: "Title can't be blank"
    assert_select "div.krudmin-ai-field.is-invalid[data-krudmin-ai-validation-field=?]", "title"
    assert_select "p#demo_ticket_title_error[hidden]", 0
    assert_select "p#demo_ticket_title_error span", text: "Title can't be blank"
    assert_select "input#demo_ticket_title[aria-invalid=?]", "true"
  end

  test "an unwritable field describes the access note alongside its error node" do
    get new_ticket_path

    assert_select "input#demo_ticket_title[aria-describedby]" do |inputs|
      assert_not_includes inputs.first["aria-describedby"], "access-note"
    end
  end

  test "nested rows project their own child model rules with row scoped ids" do
    ticket = DemoTicket.create!(tenant: "northwind", title: "Nested", state: "open", priority: "normal", assignee: @agent.name)
    ticket.passengers.create!(tenant: "northwind", name: "Robin", position: 1)

    get edit_ticket_path(ticket)

    assert_response :success
    assert_select "div.krudmin-ai-field[data-krudmin-ai-validation-field=?]", "name" do |fields|
      rules = JSON.parse(fields.first["data-krudmin-ai-validation-rules"])
      assert rules["required"]
      assert_equal "Name can't be blank", rules.dig("messages", "required")
    end
    assert_select "p#demo_ticket_passengers_attributes_0_name_error[hidden]"
    assert_select "input#demo_ticket_passengers_attributes_0_name[required]"
  end

  test "inline editing renders the shared field markup under its own validation controller" do
    DemoTicket.create!(tenant: "northwind", title: "Inline", state: "open", priority: "normal", assignee: @agent.name)

    get tickets_path

    assert_response :success
    assert_select "form.krudmin-ai-inline-edit[data-controller~=?]", "krudmin-ai-form-validation"
    assert_select "form.krudmin-ai-inline-edit div.krudmin-ai-field[data-krudmin-ai-validation-field=?]", "priority"
    assert_select "form.krudmin-ai-inline-edit label.krudmin-ai-sr-only"
    assert_select "form.krudmin-ai-inline-edit p.krudmin-ai-field-error[hidden]"
  end

  private

  def sign_in(user)
    post session_path, params: { demo_user_id: user.id }
    assert_redirected_to tickets_path
  end
end
