class AddCxpIdToSalesman < ActiveRecord::Migration[5.0]
  def change
    add_column :salesmen, :cxp_id, :string
  end
end
