class AddRoomToBoards < ActiveRecord::Migration
  def change
    add_column :boards, :room, :string
  end
end
