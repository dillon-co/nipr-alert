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

ActiveRecord::Schema.define(version: 20170901064304) do

  create_table "admins", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.index ["email"], name: "index_admins_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true, using: :btree
  end

  create_table "adp_employees", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "associate_oid"
    t.string   "associate_id"
    t.string   "position_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "job_title"
    t.string   "department_name"
    t.string   "department_id"
    t.integer  "agent_indicator"
    t.date     "hire_date"
    t.date     "position_start_date"
    t.date     "class_start_date"
    t.date     "class_end_date"
    t.string   "trainer"
    t.string   "uptraining_class"
    t.integer  "compliance_status"
    t.integer  "deleted"
    t.string   "agent_supervisor"
    t.string   "pod"
    t.string   "agent_site"
    t.string   "client"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "salesman_id"
    t.string   "npn"
    t.index ["salesman_id"], name: "index_adp_employees_on_salesman_id", using: :btree
  end

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
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.string   "position_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "associate_oid"
    t.string   "associate_id"
    t.string   "adp_position_id"
    t.string   "job_title"
    t.string   "department_name"
    t.string   "department_id"
    t.integer  "agent_indicator"
    t.date     "hire_date"
    t.date     "position_start_date"
    t.date     "class_start_date"
    t.date     "class_end_date"
    t.string   "trainer"
    t.string   "uptraining_class"
    t.integer  "compliance_status"
    t.integer  "deleted"
    t.string   "agent_supervisor"
    t.string   "pod"
    t.string   "agent_site"
    t.string   "client"
    t.string   "username"
    t.string   "cxp_employee_id"
    t.string   "jit_sites_not_appointed_in"
  end

  create_table "stag_adp_employeeinfos", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "associate_id"
    t.string   "associate_oid"
    t.string   "given_name"
    t.string   "family_name"
    t.string   "formatted_name"
    t.string   "gender"
    t.string   "primary_indicator"
    t.string   "addressline_one"
    t.string   "city"
    t.string   "country"
    t.string   "zipcode"
    t.string   "state"
    t.string   "home_work_location_city"
    t.string   "home_work_location_state"
    t.string   "home_work_location_zip"
    t.string   "home_work_location_address"
    t.string   "home_work_location_code"
    t.string   "department_value"
    t.string   "department_code"
    t.string   "business_unit"
    t.string   "n_number"
    t.string   "oiggsa"
    t.string   "agent_id"
    t.string   "siebel_id"
    t.string   "siebel_pin"
    t.string   "siebel_password"
    t.string   "temp_password"
    t.string   "temp_token"
    t.string   "npn"
    t.string   "trainer"
    t.string   "training_start_date"
    t.string   "training_grad_date"
    t.string   "training_compliance_status"
    t.string   "cap_level"
    t.date     "cap_date"
    t.string   "nice_skill_team"
    t.string   "phone_number"
    t.string   "email1"
    t.string   "email2"
    t.string   "position_status_code"
    t.string   "positionstatus_value"
    t.string   "positionreason_code"
    t.string   "positionreason_value"
    t.date     "hire_date"
    t.date     "start_date"
    t.date     "termination_date"
    t.string   "position_id"
    t.string   "position_oid"
    t.string   "group_code"
    t.date     "origional_hire_date"
    t.date     "origional_termination_date"
    t.string   "worker_status"
    t.string   "worker_type"
    t.string   "job_code"
    t.string   "job_value"
    t.string   "reports_to_oid"
    t.string   "reports_to_id"
    t.string   "reports_to_name"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
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
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "salesman_id"
    t.integer  "adp_employee_id"
    t.index ["adp_employee_id"], name: "index_states_on_adp_employee_id", using: :btree
    t.index ["salesman_id"], name: "index_states_on_salesman_id", using: :btree
  end

  create_table "states_agent_appointeds", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "npn",                           default: "0", null: false
    t.integer  "salesman_id"
    t.text     "appointed_state", limit: 65535
    t.string   "AK"
    t.string   "AL"
    t.string   "AR"
    t.string   "AZ"
    t.string   "CA"
    t.string   "CO"
    t.string   "CT"
    t.string   "DC"
    t.string   "DE"
    t.string   "FL"
    t.string   "GA"
    t.string   "HI"
    t.string   "IA"
    t.string   "IDH"
    t.string   "IL"
    t.string   "IN"
    t.string   "KS"
    t.string   "KY"
    t.string   "LA"
    t.string   "MA"
    t.string   "ME"
    t.string   "MD"
    t.string   "MI"
    t.string   "MN"
    t.string   "MS"
    t.string   "MO"
    t.string   "MT"
    t.string   "NB"
    t.string   "NC"
    t.string   "ND"
    t.string   "NE"
    t.string   "NH"
    t.string   "NJ"
    t.string   "NM"
    t.string   "NV"
    t.string   "NY"
    t.string   "OH"
    t.string   "OK"
    t.string   "ON"
    t.string   "OR"
    t.string   "PA"
    t.string   "PR"
    t.string   "RI"
    t.string   "SC"
    t.string   "SD"
    t.string   "TN"
    t.string   "TX"
    t.string   "UT"
    t.string   "VA"
    t.string   "VT"
    t.string   "WA"
    t.string   "WI"
    t.string   "WV"
    t.string   "WY"
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.index ["salesman_id"], name: "index_states_agent_appointeds_on_salesman_id", using: :btree
  end

  add_foreign_key "adp_employees", "salesmen"
  add_foreign_key "licenses", "salesmen"
  add_foreign_key "states", "adp_employees"
  add_foreign_key "states_agent_appointeds", "salesmen"
end
