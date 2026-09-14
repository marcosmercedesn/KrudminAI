class CreateOperationsShowcase < ActiveRecord::Migration[8.1]
  def change
    create_table :demo_locations do |t|
      t.string :tenant, null: false
      t.string :name, null: false
      t.string :region, null: false
      t.string :timezone, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :demo_locations, %i[tenant name], unique: true

    create_table :demo_vendors do |t|
      t.string :tenant, null: false
      t.string :name, null: false
      t.string :service_tier, null: false
      t.string :support_email
      t.boolean :preferred, null: false, default: false
      t.timestamps
    end
    add_index :demo_vendors, %i[tenant name], unique: true

    create_table :demo_assets do |t|
      t.string :tenant, null: false
      t.string :name, null: false
      t.text :description
      t.string :contact_email
      t.string :access_code
      t.string :lifecycle, null: false
      t.string :asset_tag, null: false
      t.string :serial_number
      t.decimal :purchase_price, precision: 12, scale: 2
      t.decimal :uptime_target, precision: 5, scale: 2
      t.date :installed_on
      t.time :maintenance_window
      t.datetime :commissioned_at
      t.boolean :active, null: false, default: true
      t.json :configuration
      t.references :demo_location, null: false, foreign_key: true
      t.references :demo_vendor, null: false, foreign_key: true
      t.timestamps
    end
    add_index :demo_assets, %i[tenant asset_tag], unique: true

    create_table :demo_asset_profiles do |t|
      t.references :demo_asset, null: false, foreign_key: true, index: { unique: true }
      t.string :tenant, null: false
      t.string :network_address
      t.string :rack_position
      t.string :power_source
      t.timestamps
    end

    create_table :demo_maintenance_tasks do |t|
      t.references :demo_asset, null: false, foreign_key: true
      t.string :tenant, null: false
      t.string :title, null: false
      t.string :status, null: false, default: "planned"
      t.date :due_on
      t.integer :estimated_minutes, null: false, default: 30
      t.timestamps
    end
    add_index :demo_maintenance_tasks, %i[demo_asset_id tenant]

    create_table :active_storage_blobs do |t|
      t.string :key, null: false
      t.string :filename, null: false
      t.string :content_type
      t.text :metadata
      t.string :service_name, null: false
      t.bigint :byte_size, null: false
      t.string :checksum
      t.datetime :created_at, null: false
      t.index :key, unique: true
    end

    create_table :active_storage_attachments do |t|
      t.string :name, null: false
      t.references :record, null: false, polymorphic: true, index: false
      t.references :blob, null: false
      t.datetime :created_at, null: false
      t.index %i[record_type record_id name blob_id], name: "index_active_storage_attachments_uniqueness", unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end

    create_table :action_text_rich_texts do |t|
      t.string :name, null: false
      t.text :body
      t.references :record, null: false, polymorphic: true, index: false
      t.timestamps
      t.index %i[record_type record_id name], name: "index_action_text_rich_texts_uniqueness", unique: true
    end
  end
end
