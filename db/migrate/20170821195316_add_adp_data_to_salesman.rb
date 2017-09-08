class AddAdpDataToSalesman < ActiveRecord::Migration[5.0]
  def change
    add_column :salesmen, :associate_oid, :string
    add_column :salesmen, :associate_id, :string
    add_column :salesmen, :adp_position_id, :string
    add_column :salesmen, :job_title, :string
    add_column :salesmen, :department_name, :string
    add_column :salesmen, :department_id, :string
    add_column :salesmen, :agent_indicator, :integer
    add_column :salesmen, :hire_date, :date
    add_column :salesmen, :position_start_date, :date
    add_column :salesmen, :class_start_date, :date
    add_column :salesmen, :class_end_date, :date
    add_column :salesmen, :trainer, :string
    add_column :salesmen, :uptraining_class, :string
    add_column :salesmen, :compliance_status, :integer
    add_column :salesmen, :deleted, :integer
    add_column :salesmen, :agent_supervisor, :string
    add_column :salesmen, :pod, :string
    add_column :salesmen, :agent_site, :string
    add_column :salesmen, :client, :string
  end
end
