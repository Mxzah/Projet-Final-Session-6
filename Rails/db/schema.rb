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

ActiveRecord::Schema[8.1].define(version: 2026_02_25_120000) do
  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "availabilities", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "available_id", null: false
    t.string "available_type", limit: 50, null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.datetime "end_at"
    t.datetime "start_at", null: false
    t.index ["available_type", "available_id"], name: "idx_availabilities_type_id"
  end

  create_table "categories", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", limit: 100, null: false
    t.integer "position", default: 0, null: false
    t.index ["name"], name: "uniq_categories_name", unique: true
    t.index ["position"], name: "uniq_categories_position", unique: true
  end

  create_table "combo_items", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "combo_id", null: false
    t.datetime "deleted_at"
    t.bigint "item_id", null: false
    t.integer "quantity", null: false
    t.index ["combo_id", "item_id"], name: "uniq_combo_items", unique: true
    t.index ["combo_id"], name: "index_combo_items_on_combo_id"
    t.index ["deleted_at"], name: "idx_combo_items_deleted_at"
    t.index ["item_id"], name: "index_combo_items_on_item_id"
  end

  create_table "combos", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "description"
    t.string "name", limit: 100, null: false
    t.decimal "price", precision: 6, scale: 2, null: false
    t.index ["deleted_at"], name: "idx_combos_deleted_at"
  end

  create_table "items", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "description"
    t.string "name", limit: 100, null: false
    t.decimal "price", precision: 6, scale: 2, null: false
    t.index ["category_id"], name: "index_items_on_category_id"
    t.index ["deleted_at"], name: "idx_items_deleted_at"
  end

  create_table "order_lines", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "note"
    t.bigint "order_id", null: false
    t.bigint "orderable_id", null: false
    t.string "orderable_type", limit: 50, null: false
    t.integer "quantity", null: false
    t.string "status", limit: 20, default: "sent", null: false
    t.decimal "unit_price", precision: 6, scale: 2, null: false
    t.index ["order_id"], name: "index_order_lines_on_order_id"
    t.index ["orderable_type", "orderable_id"], name: "idx_order_lines_type_id"
    t.index ["status"], name: "idx_order_lines_status"
  end

  create_table "orders", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.datetime "ended_at"
    t.integer "nb_people", null: false
    t.string "note"
    t.bigint "server_id"
    t.bigint "table_id", null: false
    t.decimal "tip", precision: 5, scale: 2
    t.bigint "vibe_id"
    t.index ["client_id"], name: "idx_orders_client_id"
    t.index ["created_at"], name: "idx_orders_created_at"
    t.index ["deleted_at", "ended_at"], name: "idx_orders_deleted_ended"
    t.index ["deleted_at"], name: "idx_orders_deleted_at"
    t.index ["server_id"], name: "idx_orders_server_id"
    t.index ["table_id"], name: "index_orders_on_table_id"
    t.index ["vibe_id"], name: "index_orders_on_vibe_id"
  end

  create_table "reviews", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "comment", limit: 500, null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.integer "rating", null: false
    t.bigint "reviewable_id", null: false
    t.string "reviewable_type", limit: 50, null: false
    t.datetime "updated_at"
    t.bigint "user_id", null: false
    t.index ["deleted_at"], name: "idx_reviews_deleted_at"
    t.index ["reviewable_type", "reviewable_id"], name: "idx_reviews_type_id"
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "tables", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.datetime "cleaned_at"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.integer "nb_seats", null: false
    t.integer "number", null: false
    t.datetime "qr_rotated_at"
    t.string "temporary_code", limit: 50
    t.index ["deleted_at"], name: "idx_tables_deleted_at"
    t.index ["number"], name: "uniq_tables_number", unique: true
    t.index ["qr_rotated_at"], name: "idx_tables_qr_rotated_at"
    t.index ["temporary_code"], name: "uniq_tables_temporary_code", unique: true
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name", limit: 50, null: false
    t.string "last_name", limit: 50, null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "status", limit: 20, default: "active", null: false
    t.string "type", limit: 20, null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["status"], name: "idx_users_status"
    t.index ["type"], name: "idx_users_type"
  end

  create_table "vibes", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "color", limit: 7, null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "name", limit: 50, null: false
    t.index ["deleted_at"], name: "idx_vibes_deleted_at"
    t.index ["name"], name: "uniq_vibes_name", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "combo_items", "combos"
  add_foreign_key "combo_items", "items"
  add_foreign_key "items", "categories"
  add_foreign_key "order_lines", "orders"
  add_foreign_key "orders", "tables"
  add_foreign_key "orders", "users", column: "client_id"
  add_foreign_key "orders", "users", column: "server_id"
  add_foreign_key "orders", "vibes"
  add_foreign_key "reviews", "users"
end
