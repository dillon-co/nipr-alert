class CreateAdpEmployees < ActiveRecord::Migration[5.0]
  def change
    create_table :adp_employees do |t|
      t.string :associate_oid
      t.string :associate_id
      t.string :position_id
      t.string :first_name
      t.string :last_name
      t.string :job_title
      t.string :department_name
      t.string :department_id
      t.integer :agent_indicator
      t.date :hire_date
      t.date :position_start_date
      t.date :class_start_date
      t.date :class_end_date
      t.string :trainer
      t.string :uptraining_class
      t.integer :compliance_status
      t.integer :deleted
      t.string :agent_supervisor
      t.string :pod
      t.string :agent_site
      t.string :client

      t.timestamps
    end
  end
end
