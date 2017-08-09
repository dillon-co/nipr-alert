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

ActiveRecord::Schema.define(version: 20170808191330) do

  create_table "appointments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "company_name"
    t.string   "fein"
    t.string   "cocode"
    t.string   "line_of_authority"
    t.string   "loa_code"
    t.string   "status"
    t.string   "termination_reason"
    t.date     "status_reason_date"
    t.date     "appont_renewal_date"
    t.string   "agency_affiliations"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "state_id"
    t.string   "county_code"
    t.index ["state_id"], name: "index_appointments_on_state_id", using: :btree
  end

  create_table "licenses", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "salesman_id"
    t.string   "license_num"
    t.date     "date_updated"
    t.date     "date_issue_license_orig"
    t.date     "date_expire_license"
    t.string   "license_class"
    t.string   "license_class_code"
    t.string   "residency_status"
    t.string   "active"
    t.string   "adhs"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.integer  "state_id"
    t.index ["salesman_id"], name: "index_licenses_on_salesman_id", using: :btree
    t.index ["state_id"], name: "index_licenses_on_state_id", using: :btree
  end

  create_table "producers", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "salesmen", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "npn"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "position_id"
    t.string   "first_name"
    t.string   "last_name"
  end

  create_table "state_details", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "loa"
    t.string   "loa_code"
    t.string   "status"
    t.string   "status_reason"
    t.string   "ce_compliance"
    t.string   "ce_credits_needed"
    t.date     "authority_issue_date"
    t.date     "status_reason_date"
    t.date     "ce_renewal_date"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.integer  "license_id"
    t.index ["license_id"], name: "index_state_details_on_license_id", using: :btree
  end

  create_table "states", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "salesman_id"
    t.index ["salesman_id"], name: "index_states_on_salesman_id", using: :btree
  end

  add_foreign_key "licenses", "salesmen"
end
