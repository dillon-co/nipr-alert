class AddAdpEmployeeToSalesman < ActiveRecord::Migration[5.0]
  def change
    add_reference :salesmen, :adp_employee, foreign_key: true
  end
end
