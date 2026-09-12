users = [
  { name: "Morgan Lee", tenant: "northwind", roles: ["support_agent"] },
  { name: "Avery Patel", tenant: "northwind", roles: ["manager"] },
  { name: "Jordan Kim", tenant: "southwind", roles: ["support_agent"] }
]

users.each { |attributes| DemoUser.find_or_create_by!(name: attributes[:name], tenant: attributes[:tenant]) { |user| user.roles = attributes[:roles] } }

tickets = [
  { tenant: "northwind", title: "Unable to export monthly orders", state: "open", priority: "high", assignee: "Morgan Lee", description: "Finance needs the September report before noon." },
  { tenant: "northwind", title: "Update billing address", state: "assigned", priority: "normal", assignee: "Avery Patel", description: "Customer confirmed the corrected address." },
  { tenant: "northwind", title: "Reset warehouse tablet", state: "resolved", priority: "low", assignee: "Morgan Lee", description: "Device was re-enrolled successfully." },
  { tenant: "southwind", title: "Inventory count is delayed", state: "open", priority: "urgent", assignee: "Jordan Kim", description: "The count is behind schedule after a scanner outage." }
]

tickets.each { |attributes| DemoTicket.find_or_create_by!(tenant: attributes[:tenant], title: attributes[:title]) { |ticket| ticket.assign_attributes(attributes) } }# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
