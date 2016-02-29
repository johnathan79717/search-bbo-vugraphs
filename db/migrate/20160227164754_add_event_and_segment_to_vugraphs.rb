class AddEventAndSegmentToVugraphs < ActiveRecord::Migration
  def change
    add_column :vugraphs, :event, :string
    add_column :vugraphs, :segment, :string
  end
end
