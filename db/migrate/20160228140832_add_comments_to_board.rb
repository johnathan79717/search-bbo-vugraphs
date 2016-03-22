class AddCommentsToBoard < ActiveRecord::Migration
  def change
    add_column :boards, :comments, :text
  end
end
