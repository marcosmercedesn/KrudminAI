class CreateDemoUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :demo_users do |table|
      table.string :name, null: false
      table.string :tenant, null: false
      table.text :roles, null: false
      table.timestamps
    end

    add_index :demo_users, [:tenant, :name], unique: true
  end
end