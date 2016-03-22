class AddLinkToBoard < ActiveRecord::Migration
  def change
    add_column :boards, :link, :string
  end
end
