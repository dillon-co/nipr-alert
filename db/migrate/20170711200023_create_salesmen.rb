class CreateSalesmen < ActiveRecord::Migration[5.0]
  def change
    create_table :salesmen do |t|
      t.string :npn

      t.timestamps
    end
  end
end
