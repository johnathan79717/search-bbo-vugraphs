class CreateVugraphs < ActiveRecord::Migration
  def change
    create_table :vugraphs do |t|
      t.text :lin_file
    end
  end
end
