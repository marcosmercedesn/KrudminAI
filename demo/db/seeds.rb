users = [
  { name: "Morgan Lee", tenant: "northwind", roles: [ "support_agent" ] },
  { name: "Avery Patel", tenant: "northwind", roles: [ "manager" ] },
  { name: "Jordan Kim", tenant: "southwind", roles: [ "support_agent" ] }
]

users.each { |attributes| DemoUser.find_or_create_by!(name: attributes[:name], tenant: attributes[:tenant]) { |user| user.roles = attributes[:roles] } }

tickets = [
  { tenant: "northwind", title: "Unable to export monthly orders", state: "open", priority: "high", assignee: "Morgan Lee", description: "Finance needs the September report before noon." },
  { tenant: "northwind", title: "Update billing address", state: "assigned", priority: "normal", assignee: "Avery Patel", description: "Customer confirmed the corrected address." },
  { tenant: "northwind", title: "Reset warehouse tablet", state: "resolved", priority: "low", assignee: "Morgan Lee", description: "Device was re-enrolled successfully." },
  { tenant: "southwind", title: "Inventory count is delayed", state: "open", priority: "urgent", assignee: "Jordan Kim", description: "The count is behind schedule after a scanner outage." }
]

tickets.each { |attributes| DemoTicket.find_or_create_by!(tenant: attributes[:tenant], title: attributes[:title]) { |ticket| ticket.assign_attributes(attributes) } }

locations = [
  { tenant: "northwind", name: "Harbor operations", region: "East", timezone: "America/New_York", active: true },
  { tenant: "northwind", name: "Mesa distribution center", region: "West", timezone: "America/Phoenix", active: true },
  { tenant: "southwind", name: "Austin field office", region: "Central", timezone: "America/Chicago", active: true }
]
locations.each { |attributes| DemoLocation.find_or_create_by!(tenant: attributes[:tenant], name: attributes[:name]) { |location| location.assign_attributes(attributes) } }

vendors = [
  { tenant: "northwind", name: "Atlas Industrial Systems", service_tier: "enterprise", support_email: "support@atlas.example", preferred: true },
  { tenant: "northwind", name: "Blue River Controls", service_tier: "priority", support_email: "service@blueriver.example", preferred: false },
  { tenant: "southwind", name: "Cedar Maintenance", service_tier: "standard", support_email: "team@cedar.example", preferred: true }
]
vendors.concat(
  (1..24).map do |number|
    {
      tenant: "northwind",
      name: format("Northwind Service Partner %02d", number),
      service_tier: DemoVendor::SERVICE_TIERS[number % DemoVendor::SERVICE_TIERS.length],
      support_email: format("partner%02d@northwind.example", number),
      preferred: false
    }
  end
)
vendors.each { |attributes| DemoVendor.find_or_create_by!(tenant: attributes[:tenant], name: attributes[:name]) { |vendor| vendor.assign_attributes(attributes) } }

asset = DemoAsset.find_or_initialize_by(tenant: "northwind", asset_tag: "42")
asset.assign_attributes(
  name: "Dock conveyor controller",
  description: "Controls the outbound conveyor system for the harbor loading lane.",
  contact_email: "operations@northwind.example",
  access_code: "showcase-only",
  lifecycle: "operational",
  serial_number: "NWC-98-4471",
  purchase_price: 18450.00,
  uptime_target: 99.50,
  installed_on: Date.new(2024, 3, 14),
  maintenance_window: "02:30",
  commissioned_at: Time.zone.parse("2024-03-20 09:30"),
  active: true,
  configuration: { network: "segmented", protocol: "modbus", ports: [ 502, 8443 ] },
  demo_location: DemoLocation.find_by!(tenant: "northwind", name: "Harbor operations"),
  demo_vendor: DemoVendor.find_by!(tenant: "northwind", name: "Atlas Industrial Systems")
)
asset.save!
asset.inspection_notes = "Quarterly inspection passed. Replace the enclosure seal during the next planned window."
asset.save!
asset.create_profile!(tenant: "northwind", network_address: "10.42.7.18", rack_position: "Dock B / cabinet 3", power_source: "UPS-2") unless asset.profile
asset.maintenance_tasks.find_or_create_by!(tenant: "northwind", title: "Inspect enclosure seal") { |task| task.assign_attributes(status: "planned", due_on: Date.current + 21, estimated_minutes: 45) }
asset.maintenance_tasks.find_or_create_by!(tenant: "northwind", title: "Verify backup configuration") { |task| task.assign_attributes(status: "scheduled", due_on: Date.current + 7, estimated_minutes: 30) }
# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
