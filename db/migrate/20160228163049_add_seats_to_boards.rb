class AddSeatsToBoards < ActiveRecord::Migration
  def change
    rename_column :boards, :players, :seats
  end
end
