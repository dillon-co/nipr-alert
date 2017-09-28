class AddAppointmentDateToState < ActiveRecord::Migration[5.0]
  def change
    add_column :states, :appointment_date, :string
  end
end
