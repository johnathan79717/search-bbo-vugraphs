class CreateLins < ActiveRecord::Migration
  def change
    create_table :lins do |t|
      t.string :filename
      t.text :body

      t.timestamps
    end
  end
end
