class CreateDemoAuditEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :demo_audit_events do |table|
      table.string :event_type, null: false
      table.string :actor_name
      table.string :tenant, null: false
      table.string :operation
      table.string :record_type
      table.string :record_identifier
      table.text :metadata
      table.timestamps
    end

    add_index :demo_audit_events, [ :tenant, :created_at ]
  end
end
