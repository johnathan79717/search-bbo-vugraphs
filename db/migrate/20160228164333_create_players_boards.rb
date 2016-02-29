class CreatePlayersBoards < ActiveRecord::Migration
  def change
    create_table :players_boards, id: false do |t|
      t.belongs_to :player, index: true
      t.belongs_to :board, index: true
    end
  end
end
