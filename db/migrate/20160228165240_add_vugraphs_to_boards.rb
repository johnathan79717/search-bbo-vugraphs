class AddVugraphsToBoards < ActiveRecord::Migration
  def change
    change_table :boards do |t|
      t.belongs_to :vugraph
    end
  end
end
