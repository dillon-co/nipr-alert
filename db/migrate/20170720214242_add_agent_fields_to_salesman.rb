class AddAgentFieldsToSalesman < ActiveRecord::Migration[5.0]
  def change
    add_column :salesmen, :position_id, :string
    add_column :salesmen, :first_name, :string
    add_column :salesmen, :last_name, :string
  end
end
