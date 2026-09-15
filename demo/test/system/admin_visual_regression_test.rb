require "application_system_test_case"

class AdminVisualRegressionTest < ApplicationSystemTestCase
  SCREENSHOT_DIRECTORY = Rails.root.join("tmp", "visual_regression").freeze

  setup do
    DemoAuditEvent.delete_all
    DemoPassenger.delete_all
    DemoTicket.delete_all
    DemoMaintenanceTask.delete_all
    DemoAssetProfile.delete_all
    DemoAsset.delete_all
    DemoLocation.delete_all
    DemoVendor.delete_all
    DemoUser.delete_all

    @agent = DemoUser.create!(name: "Morgan Lee", tenant: "northwind", roles: [ "support_agent" ])
    @ticket = DemoTicket.create!(
      tenant: "northwind",
      title: "Printer queue needs attention",
      description: "The warehouse printer queue has stopped processing labels.",
      state: "open",
      priority: "high",
      assignee: @agent.name
    )
    @active_location = DemoLocation.create!(tenant: "northwind", name: "East hub", region: "East", timezone: "America/New_York", active: true)
    @inactive_location = DemoLocation.create!(tenant: "northwind", name: "West hub", region: "West", timezone: "America/Phoenix", active: false)
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
    assert_selector "nav.krudmin-ai-breadcrumbs a", text: "Tickets"
    assert_selector "nav.krudmin-ai-breadcrumbs[aria-label='Breadcrumb']"
    assert_selector "nav.krudmin-ai-breadcrumbs [aria-current='page']", text: @ticket.title
    click_link "Edit"
    assert_selector "nav.krudmin-ai-breadcrumbs [aria-current='page']", text: "Edit ticket"
    fill_in "Title", with: "Printer queue restored"
    click_button "Save ticket"

    assert_current_path ticket_path(@ticket)
    assert_text "Printer queue restored"
  end

  test "presents boolean values as localized badges" do
    sign_in

    visit locations_path

    assert_selector ".krudmin-ai-boolean-badge--true", text: "Yes"
    assert_selector ".krudmin-ai-boolean-badge--false", text: "No"

    visit location_path(@active_location)
    assert_selector ".krudmin-ai-boolean-badge--true", text: "Yes"
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
    assert_equal [ "Added passenger" ], @ticket.passengers.reload.pluck(:name)
  end

  test "supports keyboard filtering and announces validation errors" do
    sign_in

    assert_button "Filters"
    assert_no_field "State"
    click_button "Filters"
    assert_selector "#krudmin-ai-filters:not([hidden])"
    select "resolved", from: "State"
    click_button "Apply filters"
    assert_selector "#krudmin-ai-filters:not([hidden])"
    assert_selector ".krudmin-ai-empty-state"

    visit new_ticket_path
    click_button "Save ticket"
    assert_selector "[role='alert']", text: "Ticket could not be saved"
    assert_selector "input[aria-invalid='true']"
  end

  test "renders the operations showcase fields and nested editors" do
    location = DemoLocation.create!(tenant: "northwind", name: "Harbor operations", region: "East", timezone: "America/New_York", active: true)
    vendor = DemoVendor.create!(tenant: "northwind", name: "Atlas Industrial Systems", service_tier: "enterprise", support_email: "support@atlas.example", preferred: true)
    asset = DemoAsset.create!(
      tenant: "northwind",
      name: "Dock conveyor controller",
      asset_tag: "42",
      lifecycle: "operational",
      demo_location: location,
      demo_vendor: vendor
    )
    asset.create_profile!(tenant: "northwind", network_address: "10.42.7.18", rack_position: "Dock B / cabinet 3", power_source: "UPS-2")
    asset.maintenance_tasks.create!(tenant: "northwind", title: "Inspect enclosure seal", status: "planned", due_on: Date.current + 21, estimated_minutes: 45)

    sign_in
    visit edit_asset_path(asset)

    assert_selector "fieldset", text: "Asset identity"
    assert_field "Name"
    assert_field "Contact email", type: "email"
    assert_field "Access code", type: "password"
    assert_field "Purchase price"
    assert_field "Uptime target"
    assert_field "Installed on", type: "date"
    assert_field "Maintenance window", type: "time"
    assert_field "Commissioned at", type: "datetime-local"
    assert_field "Configuration"
    assert_field "Photo", type: "file"
    assert_field "Manual", type: "file"
    assert_selector "trix-editor"
    assert_select "Demo location"
    assert_selector "[data-controller='krudmin-ai-remote-belongs-to']"
    assert_text "Deployment profile"
    assert_text "Maintenance tasks"

    click_button "Save asset"
    assert_current_path asset_path(asset)

    assert_text "[REDACTED]"
    assert_no_text "NWC-98-4471"
  end

  test "exposes named controls, keyboard focus, and sized touch targets" do
    sign_in
    visit ticket_path(@ticket)

    assert_accessibility_baseline
    assert page.evaluate_script(<<~JAVASCRIPT), "Expected every visible form control to have an accessible name"
      [...document.querySelectorAll("button, input:not([type=hidden]), select, textarea")]
        .filter((control) => control.offsetParent !== null)
        .every((control) => control.labels.length > 0 || control.getAttribute("aria-label") || control.getAttribute("aria-labelledby") || control.innerText.trim() || control.value)
    JAVASCRIPT
    assert page.evaluate_script(<<~JAVASCRIPT), "Expected visible form controls to provide a 32px minimum touch target"
      [...document.querySelectorAll("button, input:not([type=hidden]), select, textarea")]
        .filter((control) => control.offsetParent !== null)
        .every((control) => {
          const bounds = control.getBoundingClientRect()
          return bounds.width >= 32 && bounds.height >= 32
        })
    JAVASCRIPT

    edit_link = find_link("Edit")
    page.execute_script("arguments[0].focus()", edit_link)
    edit_link.send_keys(:tab)
    assert_not page.evaluate_script("document.activeElement === arguments[0]", edit_link)
    assert_operator page.evaluate_script("parseFloat(getComputedStyle(document.activeElement).outlineWidth)"), :>, 0
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

    page.send_keys(:escape)
    assert_equal "false", find("[data-sidebar-toggle]")["aria-expanded"]

    click_button "Open navigation"
    find("[data-sidebar-backdrop]").click
    assert_equal "false", find("[data-sidebar-toggle]")["aria-expanded"]

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
    assert_accessibility_baseline

    FileUtils.mkdir_p(SCREENSHOT_DIRECTORY)
    screenshot_path = SCREENSHOT_DIRECTORY.join("#{name}.png")
    page.save_screenshot(screenshot_path)
    assert File.exist?(screenshot_path), "Expected screenshot at #{screenshot_path}"
  end

  def assert_accessibility_baseline
    assert_selector "main"
    assert_selector "nav[aria-label='Main navigation']", visible: :all
    assert page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth"), "Expected no document-level horizontal overflow"

    focus_target = page.first("a, button, input, select, textarea")
    page.execute_script("arguments[0].focus()", focus_target)
    assert page.evaluate_script("document.activeElement === arguments[0]", focus_target)
    assert_operator page.evaluate_script("parseFloat(getComputedStyle(document.activeElement).outlineWidth)"), :>, 0, "Expected focused controls to have a visible outline"
  end
end
