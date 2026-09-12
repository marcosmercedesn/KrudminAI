class CreateDemoPassengers < ActiveRecord::Migration[8.1]
  def change
    create_table :demo_passengers do |table|
      table.references :demo_ticket, null: false, foreign_key: true
      table.string :tenant, null: false
      table.string :name, null: false
      table.integer :position, null: false, default: 0
      table.timestamps
    end

    add_index :demo_passengers, [:demo_ticket_id, :tenant]
  end
end