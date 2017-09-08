class CreateStagAdpEmployeeinfos < ActiveRecord::Migration[5.0]
  def change
    create_table :stag_adp_employeeinfos do |t|
      t.string :associate_id
      t.string :associate_oid, unique: true
      t.string :given_name
      t.string :family_name
      t.string :formatted_name
      t.string :gender
      t.string :primary_indicator
      t.string :addressline_one
      t.string :city
      t.string :country
      t.string :zipcode
      t.string :state
      t.string :home_work_location_city
      t.string :home_work_location_state
      t.string :home_work_location_zip
      t.string :home_work_location_address
      t.string :home_work_location_code
      t.string :department_value
      t.string :department_code
      t.string :business_unit
      t.string :n_number
      t.string :oiggsa
      t.string :agent_id
      t.string :siebel_id
      t.string :siebel_pin
      t.string :siebel_password
      t.string :temp_password
      t.string :temp_token
      t.string :npn
      t.string :trainer
      t.string :training_start_date
      t.string :training_grad_date
      t.string :training_compliance_status
      t.string :cap_level
      t.date :cap_date
      t.string :nice_skill_team
      t.string :phone_number
      t.string :email1
      t.string :email2
      t.string :position_status_code
      t.string :positionstatus_value
      t.string :positionreason_code
      t.string :positionreason_value
      t.date :hire_date
      t.date :start_date
      t.date :termination_date
      t.string :position_id
      t.string :position_oid, unique: true
      t.string :group_code
      t.date :origional_hire_date
      t.date :origional_termination_date
      t.string :worker_status
      t.string :worker_type
      t.string :job_code
      t.string :job_value
      t.string :reports_to_oid
      t.string :reports_to_id
      t.string :reports_to_name

      t.timestamps
    end
  end
end
