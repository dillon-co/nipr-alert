class CreateLicenses < ActiveRecord::Migration[5.0]
  def change
    create_table :licenses do |t|
      t.references :salesman, foreign_key: true
      t.string     :license_num
      t.date       :date_updated
      t.date       :date_issue_license_orig
      t.date       :date_expire_license
      t.string     :license_class
      t.string     :license_class_code
      t.string     :residency_status
      t.string     :active
      t.string     :adhs
      t.timestamps
    end
  end
end
