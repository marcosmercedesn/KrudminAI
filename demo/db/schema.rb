# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_12_131500) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index [ "record_type", "record_id", "name" ], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "record_id", null: false
    t.string "record_type", null: false
    t.index [ "blob_id" ], name: "index_active_storage_attachments_on_blob_id"
    t.index [ "record_type", "record_id", "name", "blob_id" ], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index [ "key" ], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "demo_asset_profiles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "demo_asset_id", null: false
    t.string "network_address"
    t.string "power_source"
    t.string "rack_position"
    t.string "tenant", null: false
    t.datetime "updated_at", null: false
    t.index [ "demo_asset_id" ], name: "index_demo_asset_profiles_on_demo_asset_id", unique: true
  end

  create_table "demo_assets", force: :cascade do |t|
    t.string "access_code"
    t.boolean "active", default: true, null: false
    t.string "asset_tag", null: false
    t.datetime "commissioned_at"
    t.json "configuration"
    t.string "contact_email"
    t.datetime "created_at", null: false
    t.integer "demo_location_id", null: false
    t.integer "demo_vendor_id", null: false
    t.text "description"
    t.date "installed_on"
    t.string "lifecycle", null: false
    t.time "maintenance_window"
    t.string "name", null: false
    t.decimal "purchase_price", precision: 12, scale: 2
    t.string "serial_number"
    t.string "tenant", null: false
    t.datetime "updated_at", null: false
    t.decimal "uptime_target", precision: 5, scale: 2
    t.index [ "demo_location_id" ], name: "index_demo_assets_on_demo_location_id"
    t.index [ "demo_vendor_id" ], name: "index_demo_assets_on_demo_vendor_id"
    t.index [ "tenant", "asset_tag" ], name: "index_demo_assets_on_tenant_and_asset_tag", unique: true
  end

  create_table "demo_audit_events", force: :cascade do |t|
    t.string "actor_name"
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.text "metadata"
    t.string "operation"
    t.string "record_identifier"
    t.string "record_type"
    t.string "tenant", null: false
    t.datetime "updated_at", null: false
    t.index [ "tenant", "created_at" ], name: "index_demo_audit_events_on_tenant_and_created_at"
  end

  create_table "demo_locations", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "region", null: false
    t.string "tenant", null: false
    t.string "timezone", null: false
    t.datetime "updated_at", null: false
    t.index [ "tenant", "name" ], name: "index_demo_locations_on_tenant_and_name", unique: true
  end

  create_table "demo_maintenance_tasks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "demo_asset_id", null: false
    t.date "due_on"
    t.integer "estimated_minutes", default: 30, null: false
    t.string "status", default: "planned", null: false
    t.string "tenant", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index [ "demo_asset_id", "tenant" ], name: "index_demo_maintenance_tasks_on_demo_asset_id_and_tenant"
    t.index [ "demo_asset_id" ], name: "index_demo_maintenance_tasks_on_demo_asset_id"
  end

  create_table "demo_passengers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "demo_ticket_id", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "tenant", null: false
    t.datetime "updated_at", null: false
    t.index [ "demo_ticket_id", "tenant" ], name: "index_demo_passengers_on_demo_ticket_id_and_tenant"
    t.index [ "demo_ticket_id" ], name: "index_demo_passengers_on_demo_ticket_id"
  end

  create_table "demo_tickets", force: :cascade do |t|
    t.datetime "archived_at"
    t.string "assignee"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "priority", null: false
    t.string "state", null: false
    t.string "tenant", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index [ "tenant", "archived_at" ], name: "index_demo_tickets_on_tenant_and_archived_at"
    t.index [ "tenant", "state" ], name: "index_demo_tickets_on_tenant_and_state"
  end

  create_table "demo_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "roles", null: false
    t.string "tenant", null: false
    t.datetime "updated_at", null: false
    t.index [ "tenant", "name" ], name: "index_demo_users_on_tenant_and_name", unique: true
  end

  create_table "demo_vendors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.boolean "preferred", default: false, null: false
    t.string "service_tier", null: false
    t.string "support_email"
    t.string "tenant", null: false
    t.datetime "updated_at", null: false
    t.index [ "tenant", "name" ], name: "index_demo_vendors_on_tenant_and_name", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "demo_asset_profiles", "demo_assets"
  add_foreign_key "demo_assets", "demo_locations"
  add_foreign_key "demo_assets", "demo_vendors"
  add_foreign_key "demo_maintenance_tasks", "demo_assets"
  add_foreign_key "demo_passengers", "demo_tickets"
end
