class RemoveAdpFromSalesman < ActiveRecord::Migration[5.0]
  def change
    remove_reference :salesmen, :adp_employee, foreign_key: true
  end
end
