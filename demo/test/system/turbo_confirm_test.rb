require "application_system_test_case"

# Turbo routes data-turbo-confirm through window.confirm, so the dialog is driven directly
# rather than asserted on markup alone.
class TurboConfirmTest < ApplicationSystemTestCase
  setup do
    DemoAuditEvent.delete_all
    DemoPassenger.delete_all
    DemoTicket.delete_all
    DemoUser.delete_all

    @manager = DemoUser.create!(name: "Avery Patel", tenant: "northwind", roles: [ "manager" ])
    @ticket = DemoTicket.create!(tenant: "northwind", title: "Printer queue", state: "open", priority: "high", assignee: "Morgan Lee")
  end

  test "dismissing the confirmation leaves the record untouched" do
    sign_in
    visit ticket_path(@ticket)

    dismiss_confirm("Assign this ticket to yourself?") do
      click_button "Assign to me"
    end

    assert_equal "Morgan Lee", @ticket.reload.assignee
    assert_equal 0, DemoAuditEvent.count
  end

  test "accepting the confirmation performs the action and navigates" do
    sign_in
    visit ticket_path(@ticket)

    accept_confirm("Assign this ticket to yourself?") do
      click_button "Assign to me"
    end

    assert_text @manager.name
    assert_current_path ticket_path(@ticket)
    assert_equal @manager.name, @ticket.reload.assignee
  end

  test "an action without a confirmation proceeds without a dialog" do
    sign_in
    visit ticket_path(@ticket)

    click_button "Resolve"

    assert_current_path ticket_path(@ticket)
    assert_equal "resolved", @ticket.reload.state
  end

  private

  def sign_in
    visit new_session_path
    click_button "Enter workspace", match: :first
    assert_current_path tickets_path
  end
end
