class CreateBoards < ActiveRecord::Migration
  def change
    create_table :boards do |t|
      t.integer :number
      t.string :players
      t.string :hands
      t.string :auction
      t.string :explanation
      t.string :event

      t.timestamps
    end
  end
end