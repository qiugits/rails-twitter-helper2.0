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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20161015071238) do

  create_table "tweets", primary_key: "status_id", force: :cascade do |t|
    t.datetime "created_at",                       null: false
    t.text     "text"
    t.string   "media"
    t.string   "source"
    t.integer  "in_reply_to_status_id", limit: 32
    t.string   "user_screen_name"
    t.string   "user_profile_image"
    t.string   "tag"
    t.text     "memo"
    t.datetime "updated_at",                       null: false
    t.index ["status_id"], name: "sqlite_autoindex_tweets_1", unique: true
  end

end
