class AddIndexToBoard < ActiveRecord::Migration
  def change
    add_index :boards, :vugraph_id
  end
end
