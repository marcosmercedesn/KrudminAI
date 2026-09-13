class CreateDemoTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :demo_tickets do |table|
      table.string :tenant, null: false
      table.string :title, null: false
      table.string :state, null: false
      table.string :priority, null: false
      table.string :assignee
      table.text :description
      table.timestamps
    end

    add_index :demo_tickets, [ :tenant, :state ]
  end
end
