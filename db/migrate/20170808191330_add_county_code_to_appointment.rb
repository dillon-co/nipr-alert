class AddCountyCodeToAppointment < ActiveRecord::Migration[5.0]
  def change
    add_column :appointments, :county_code, :string
  end
end
