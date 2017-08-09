class CreateProducers < ActiveRecord::Migration[5.0]
  def change
    create_table :producers do |t|
      t.string :title

      t.timestamps
    end
  end
end
