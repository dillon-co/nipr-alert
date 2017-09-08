class AddNpnToAdpEmployee < ActiveRecord::Migration[5.0]
  def change
    add_column :adp_employees, :npn, :string
  end
end
