class AddLinkToBoard < ActiveRecord::Migration
  def change
    add_column :board, :link, :string
  end
end
