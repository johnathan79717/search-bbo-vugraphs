class AddTimestampsToVugraphs < ActiveRecord::Migration
  def up
    add_timestamps :vugraphs
    change_column :vugraphs, :created_at, :datetime, null: false
    change_column :vugraphs, :updated_at, :datetime, null: false
  end

  def down
    remove_timestamps :vugraphs
  end
end
