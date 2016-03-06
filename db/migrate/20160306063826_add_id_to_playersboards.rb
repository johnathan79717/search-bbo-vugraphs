class AddIdToPlayersboards < ActiveRecord::Migration
  def change
    add_column :players_boards, :id, :primary_key
  end
end
