class CreateStateDetails < ActiveRecord::Migration[5.0]
  def change
    create_table :state_details do |t|


      t.string :loa
      t.string :loa_code
      t.string :status
      t.string :status_reason
      t.string :ce_compliance
      t.string :ce_credits_needed

      t.date :authority_issue_date
      t.date :status_reason_date
      t.date :ce_renewal_date

      t.timestamps
    end
  end
end
