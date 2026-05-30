# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_30_194306) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "communities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_communities_on_deleted_at"
    t.index ["name"], name: "index_communities_on_name", unique: true, where: "(deleted_at IS NULL)"
  end

  create_table "messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.float "ai_sentiment_score"
    t.uuid "community_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.uuid "parent_message_id"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.string "user_ip", null: false
    t.index ["community_id"], name: "index_messages_on_community_id"
    t.index ["parent_message_id"], name: "index_messages_on_parent_message_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["username"], name: "index_users_on_username", unique: true, where: "(deleted_at IS NULL)"
  end

  add_foreign_key "messages", "communities"
  add_foreign_key "messages", "messages", column: "parent_message_id"
  add_foreign_key "messages", "users"
end
