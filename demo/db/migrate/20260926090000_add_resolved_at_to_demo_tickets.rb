class AddResolvedAtToDemoTickets < ActiveRecord::Migration[8.1]
  def change
    add_column :demo_tickets, :resolved_at, :datetime
  end
end