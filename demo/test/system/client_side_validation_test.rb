require "application_system_test_case"

class ClientSideValidationTest < ApplicationSystemTestCase
  setup do
    DemoAuditEvent.delete_all
    DemoPassenger.delete_all
    DemoTicket.delete_all
    DemoUser.delete_all

    @agent = DemoUser.create!(name: "Morgan Lee", tenant: "northwind", roles: [ "support_agent" ])
  end

  test "an invalid submission is stopped in the browser and never reaches the server" do
    sign_in
    open_new_ticket_form

    fill_in "Title", with: ""
    click_button "Save ticket"

    assert_selector "p#demo_ticket_title_error", text: "Title can't be blank"
    assert_selector ".krudmin-ai-field.is-invalid"
    assert_equal "true", find("#demo_ticket_title")["aria-invalid"]
    assert_current_path new_ticket_path
    assert_equal 0, DemoTicket.count
  end

  test "a blocked submission focuses and scrolls to the first field needing attention" do
    sign_in
    open_new_ticket_form

    page.execute_script("window.scrollTo(0, document.body.scrollHeight)")
    click_button "Save ticket"

    assert_selector "p#demo_ticket_title_error", text: "Title can't be blank"
    assert_equal "demo_ticket_title", page.evaluate_script("document.activeElement.id")
    assert_scrolled_into_view "demo_ticket_title"
  end

  test "the summary lists anchored messages for every field needing attention" do
    sign_in
    open_new_ticket_form

    click_button "Save ticket"

    within ".krudmin-ai-validation-summary" do
      assert_link "Title can't be blank", href: "#demo_ticket_title"
    end
  end

  test "correcting a field clears its message and lets the submission through" do
    sign_in
    open_new_ticket_form

    click_button "Save ticket"
    assert_selector "p#demo_ticket_title_error", text: "Title can't be blank"

    fill_in "Title", with: "Recovered ticket"
    assert_no_selector "p#demo_ticket_title_error", text: "Title can't be blank"

    fill_in "State", with: "open"
    fill_in "Priority", with: "normal"
    click_button "Save ticket"

    assert_text "Recovered ticket"
    assert_equal 1, DemoTicket.count
  end

  test "a nested row added after load is validated like the rest of the form" do
    ticket = DemoTicket.create!(tenant: "northwind", title: "Nested", state: "open", priority: "normal", assignee: @agent.name)
    sign_in
    visit edit_ticket_path(ticket)
    await_controller "form.krudmin-ai-form-grid"

    click_button "Add Passenger"
    click_button "Save ticket"

    assert_selector ".krudmin-ai-nested-row .krudmin-ai-field-error", text: "Name can't be blank"
    assert_equal 0, DemoPassenger.count
  end

  test "a row marked for removal is excluded from validation" do
    ticket = DemoTicket.create!(tenant: "northwind", title: "Nested", state: "open", priority: "normal", assignee: @agent.name)
    ticket.passengers.create!(tenant: "northwind", name: "Robin", position: 1)
    sign_in
    visit edit_ticket_path(ticket)
    await_controller "form.krudmin-ai-form-grid"

    within all(".krudmin-ai-nested-row").first do
      fill_in "Name", with: ""
      click_button "Remove Passenger"
    end
    click_button "Save ticket"

    assert_current_path ticket_path(ticket)
    assert_equal 0, ticket.passengers.reload.count
  end

  test "inline editing validates within its own row form" do
    ticket = DemoTicket.create!(tenant: "northwind", title: "Inline", state: "open", priority: "normal", assignee: @agent.name)
    sign_in
    await_controller "form.krudmin-ai-inline-edit"

    within "form.krudmin-ai-inline-edit" do
      fill_in "Priority", with: ""
      click_button "Save ticket"
      assert_selector ".krudmin-ai-field-error", text: "Priority can't be blank"
    end

    assert_equal "normal", ticket.reload.priority
  end

  test "a successful inline edit keeps the list in place and reports through the flash" do
    ticket = DemoTicket.create!(tenant: "northwind", title: "Inline", state: "open", priority: "normal", assignee: @agent.name)
    sign_in
    await_controller "form.krudmin-ai-inline-edit"

    within "form.krudmin-ai-inline-edit" do
      fill_in "Priority", with: "urgent"
      click_button "Save ticket"
    end

    assert_selector "#krudmin-ai-flash", text: "ticket updated and audited."
    assert_current_path tickets_path
    assert_equal "urgent", ticket.reload.priority
  end

  private

  def sign_in
    visit new_session_path
    click_button "Enter workspace", match: :first
    assert_current_path tickets_path
  end

  def open_new_ticket_form
    visit new_ticket_path
    await_controller "form.krudmin-ai-form-grid"
  end

  # noValidate reflects to the novalidate attribute, so this waits on proof that the controller
  # connected. Without it a test can submit before Stimulus boots and reach the server instead.
  def await_controller(selector)
    assert_selector "#{selector}[novalidate]", visible: :all, match: :first
  end

  def in_viewport?(id)
    page.evaluate_script(<<~JS)
      (() => {
        const rect = document.getElementById(#{id.to_json}).getBoundingClientRect()
        return rect.top >= 0 && rect.bottom <= window.innerHeight
      })()
    JS
  end

  # Smooth scrolling settles asynchronously, so the viewport is polled rather than sampled once.
  def assert_scrolled_into_view(id)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + Capybara.default_max_wait_time
    until in_viewport?(id)
      flunk "Expected ##{id} to be scrolled into view" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
    end

    assert in_viewport?(id)
  end
end
