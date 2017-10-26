class AddLicensedToState < ActiveRecord::Migration[5.0]
  def change
    add_column :states, :licensed, :boolean
  end
end
