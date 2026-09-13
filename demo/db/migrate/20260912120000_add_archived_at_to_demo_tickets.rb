class AddArchivedAtToDemoTickets < ActiveRecord::Migration[8.1]
  def change
    add_column :demo_tickets, :archived_at, :datetime
    add_index :demo_tickets, [ :tenant, :archived_at ]
  end
end
