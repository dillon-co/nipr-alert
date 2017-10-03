class ChangeStartDate < ActiveRecord::Migration[5.0]
  def change
    change_column :salesmen, :start_date, :date
  end
end
