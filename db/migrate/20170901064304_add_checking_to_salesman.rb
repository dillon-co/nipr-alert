class AddCheckingToSalesman < ActiveRecord::Migration[5.0]
  def change
    add_column :salesmen, :jit_sites_not_appointed_in, :string
  end
end
