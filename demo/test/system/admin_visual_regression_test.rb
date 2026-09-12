require "application_system_test_case"

class AdminVisualRegressionTest < ApplicationSystemTestCase
  SCREENSHOT_DIRECTORY = Rails.root.join("tmp", "visual_regression").freeze

  setup do
    DemoAuditEvent.delete_all
    DemoTicket.delete_all
    DemoUser.delete_all

    @agent = DemoUser.create!(name: "Morgan Lee", tenant: "northwind", roles: ["support_agent"])
    @ticket = DemoTicket.create!(
      tenant: "northwind",
      title: "Printer queue needs attention",
      description: "The warehouse printer queue has stopped processing labels.",
      state: "open",
      priority: "high",
      assignee: @agent.name
    )
  end

  test "captures authenticated resource and dashboard screens in each theme" do
    sign_in

    %w[light dark].each do |theme|
      apply_theme(theme)
      capture_screen("tickets-#{theme}")

      visit new_ticket_path
      capture_screen("ticket-new-#{theme}")

      visit edit_ticket_path(@ticket)
      capture_screen("ticket-edit-#{theme}")

      visit ticket_path(@ticket)
      capture_screen("ticket-show-#{theme}")

      visit dashboard_path
      capture_screen("dashboard-#{theme}")
    end
  end

  test "edits a ticket through the engine-owned default resource pages" do
    sign_in

    click_link @ticket.title
    click_link "Edit"
    fill_in "Title", with: "Printer queue restored"
    click_button "Save ticket"

    assert_current_path ticket_path(@ticket)
    assert_text "Printer queue restored"
  end

  test "adds and removes passengers through the nested editor" do
    @ticket.passengers.create!(tenant: "northwind", name: "Existing passenger", position: 1)
    sign_in

    visit edit_ticket_path(@ticket)
    click_button "Add Passenger"
    click_button "Add Passenger" if all(".krudmin-ai-nested-row").length == 1
    assert_selector ".krudmin-ai-nested-row", count: 2

    within all(".krudmin-ai-nested-row").last do
      fill_in "Name", with: "Added passenger"
      fill_in "Position", with: "2"
    end
    within all(".krudmin-ai-nested-row").first do
      click_button "Remove Passenger"
    end
    click_button "Save ticket"

    assert_current_path ticket_path(@ticket)
    assert_equal ["Added passenger"], @ticket.passengers.reload.pluck(:name)
  end

  test "captures desktop rail and mobile drawer states" do
    sign_in

    resize_to(1440, 900)
    visit tickets_path
    capture_screen("navigation-desktop-expanded")

    page.execute_script("localStorage.setItem('krudmin-ai-sidebar-collapsed', 'true')")
    visit tickets_path
    assert_equal "true", page.evaluate_script("document.documentElement.dataset.sidebarCollapsed")
    assert_equal "false", find("[data-sidebar-toggle]")["aria-expanded"]
    assert_equal "none", page.evaluate_script("getComputedStyle(document.querySelector('.site-header')).display")
    assert_operator page.evaluate_script("document.querySelector('.page-shell').getBoundingClientRect().width"), :>, 0
    capture_screen("navigation-desktop-collapsed")

    resize_to(768, 900)
    visit tickets_path
    apply_theme("light")
    capture_screen("tickets-tablet-light")
    apply_theme("dark")
    capture_screen("tickets-tablet-dark")

    resize_to(390, 844)
    visit tickets_path
    apply_theme("light")
    assert_equal "false", find("[data-sidebar-toggle]")["aria-expanded"]
    capture_screen("navigation-mobile-closed-light")

    click_button "Open navigation"
    assert_equal "true", find("[data-sidebar-toggle]")["aria-expanded"]
    capture_screen("navigation-mobile-open-light")

    visit tickets_path
    apply_theme("dark")
    capture_screen("navigation-mobile-closed-dark")
  end

  private

  def sign_in
    visit new_session_path
    click_button "Enter workspace", match: :first
    assert_current_path tickets_path
  end

  def apply_theme(theme)
    page.execute_script("localStorage.setItem('krudmin-ai-theme', arguments[0])", theme)
    visit current_path
    assert_equal theme, page.evaluate_script("document.documentElement.dataset.theme")
  end

  def resize_to(width, height)
    page.current_window.resize_to(width, height)
  end

  def capture_screen(name)
    assert_selector "h1"
    assert_selector "svg.krudmin-ai-icon", minimum: 1
    assert page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth"), "Expected no document-level horizontal overflow"

    FileUtils.mkdir_p(SCREENSHOT_DIRECTORY)
    screenshot_path = SCREENSHOT_DIRECTORY.join("#{name}.png")
    page.save_screenshot(screenshot_path)
    assert File.exist?(screenshot_path), "Expected screenshot at #{screenshot_path}"
  end
end