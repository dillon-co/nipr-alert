class CreateAppointments < ActiveRecord::Migration[5.0]
  def change
    create_table :appointments do |t|
      t.string :company_name
      t.string :fein
      t.string :cocode
      t.string :line_of_authority
      t.string :loa_code
      t.string :status
      t.string :termination_reason
      t.date   :status_reason_date
      t.date   :appont_renewal_date
      t.string :agency_affiliations

      t.timestamps
    end
  end
end
