class AddAppointedToStates < ActiveRecord::Migration[5.0]
  def change
    add_column :states, :appointed, :boolean
  end
end
