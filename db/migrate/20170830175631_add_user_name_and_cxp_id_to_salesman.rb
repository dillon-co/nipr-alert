class AddUserNameAndCxpIdToSalesman < ActiveRecord::Migration[5.0]
  def change
    add_column :salesmen, :username, :string
    add_column :salesmen, :cxp_employee_id, :string
  end
end
