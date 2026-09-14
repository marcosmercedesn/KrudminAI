class NormalizeOperationsAssetIdentifiers < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE demo_assets
      SET asset_tag = REPLACE(asset_tag, 'AST-', '')
      WHERE asset_tag LIKE 'AST-%'
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE demo_assets
      SET asset_tag = 'AST-' || printf('%05d', CAST(asset_tag AS INTEGER))
      WHERE asset_tag NOT LIKE 'AST-%'
    SQL
  end
end
