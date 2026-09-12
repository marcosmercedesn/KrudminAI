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

ActiveRecord::Schema[8.1].define(version: 2026_09_12_090200) do
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
    t.index ["tenant", "created_at"], name: "index_demo_audit_events_on_tenant_and_created_at"
  end

  create_table "demo_tickets", force: :cascade do |t|
    t.string "assignee"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "priority", null: false
    t.string "state", null: false
    t.string "tenant", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant", "state"], name: "index_demo_tickets_on_tenant_and_state"
  end

  create_table "demo_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "roles", null: false
    t.string "tenant", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant", "name"], name: "index_demo_users_on_tenant_and_name", unique: true
  end
end
