class AddMainReferences < ActiveRecord::Migration[5.0]
  def change
    add_reference :licenses, :state, index: true
    add_reference :appointments, :state, index: true
    add_reference :state_details, :license, index: true
    add_reference :states, :salesman, index: true
  end
end
