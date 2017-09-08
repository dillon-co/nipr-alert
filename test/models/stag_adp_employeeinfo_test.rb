# == Schema Information
#
# Table name: stag_adp_employeeinfos
#
#  id                         :integer          not null, primary key
#  associate_id               :string(255)
#  associate_oid              :string(255)
#  given_name                 :string(255)
#  family_name                :string(255)
#  formatted_name             :string(255)
#  gender                     :string(255)
#  primary_indicator          :string(255)
#  addressline_one            :string(255)
#  city                       :string(255)
#  country                    :string(255)
#  zipcode                    :string(255)
#  state                      :string(255)
#  home_work_location_city    :string(255)
#  home_work_location_state   :string(255)
#  home_work_location_zip     :string(255)
#  home_work_location_address :string(255)
#  home_work_location_code    :string(255)
#  department_value           :string(255)
#  department_code            :string(255)
#  business_unit              :string(255)
#  n_number                   :string(255)
#  oiggsa                     :string(255)
#  agent_id                   :string(255)
#  siebel_id                  :string(255)
#  siebel_pin                 :string(255)
#  siebel_password            :string(255)
#  temp_password              :string(255)
#  temp_token                 :string(255)
#  npn                        :string(255)
#  trainer                    :string(255)
#  training_start_date        :string(255)
#  training_grad_date         :string(255)
#  training_compliance_status :string(255)
#  cap_level                  :string(255)
#  cap_date                   :date
#  nice_skill_team            :string(255)
#  phone_number               :string(255)
#  email1                     :string(255)
#  email2                     :string(255)
#  position_status_code       :string(255)
#  positionstatus_value       :string(255)
#  positionreason_code        :string(255)
#  positionreason_value       :string(255)
#  hire_date                  :date
#  start_date                 :date
#  termination_date           :date
#  position_id                :string(255)
#  position_oid               :string(255)
#  group_code                 :string(255)
#  origional_hire_date        :date
#  origional_termination_date :date
#  worker_status              :string(255)
#  worker_type                :string(255)
#  job_code                   :string(255)
#  job_value                  :string(255)
#  reports_to_oid             :string(255)
#  reports_to_id              :string(255)
#  reports_to_name            :string(255)
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#

require 'test_helper'

class StagAdpEmployeeinfoTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
