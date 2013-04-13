class DropTableLin < ActiveRecord::Migration
  def up
   drop_table :lins
  end

  def down
    create_table :lins do |t|
      t.string :filename
      t.text :body

      t.timestamps
    end
  end
end