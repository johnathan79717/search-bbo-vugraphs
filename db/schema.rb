# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20160229094248) do

  create_table "blacklists", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "boards", :force => true do |t|
    t.integer  "number"
    t.string   "seats"
    t.string   "hands"
    t.string   "auction"
    t.string   "explanation"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.text     "comments"
    t.integer  "vugraph_id"
  end

  create_table "players", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "players_boards", :id => false, :force => true do |t|
    t.integer "player_id"
    t.integer "board_id"
  end

  create_table "vugraphs", :force => true do |t|
    t.text     "lin_file"
    t.string   "event"
    t.string   "segment"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

end
