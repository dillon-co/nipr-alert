class AddSalesmanToAdpEmployee < ActiveRecord::Migration[5.0]
  def change
    add_reference :adp_employees, :salesman, foreign_key: true
  end
end
