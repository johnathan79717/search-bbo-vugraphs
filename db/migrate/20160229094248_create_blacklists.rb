class CreateBlacklists < ActiveRecord::Migration
  def change
    create_table :blacklists do |t|

      t.timestamps
    end
  end
end
