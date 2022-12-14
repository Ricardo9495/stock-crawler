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

ActiveRecord::Schema[7.0].define(version: 2022_08_31_080318) do
  create_table "companies", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.string "ticker"
    t.integer "cik"
    t.string "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "daily_reports", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.float "price"
    t.string "timestamp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_daily_reports_on_company_id"
  end

  create_table "quater_reports", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "company_id"
    t.string "quater"
    t.string "start_date"
    t.string "end_date"
    t.integer "equity"
    t.float "earning_per_share"
    t.integer "share_out_standing"
    t.integer "net_income"
    t.integer "d_d_a_p"
    t.integer "long_term_debt_current"
    t.integer "long_term_debt_non_current"
    t.integer "commercial_paper"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_quater_reports_on_company_id"
  end

  add_foreign_key "daily_reports", "companies"
  add_foreign_key "quater_reports", "companies"
end
