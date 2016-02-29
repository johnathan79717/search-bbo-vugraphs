class RemoveLinkEventFromBoard < ActiveRecord::Migration
  def up
    remove_column :boards, :link
    remove_column :boards, :event
  end

  def down
    add_column :boards, :event, :string
    add_column :boards, :link, :string
  end
end
