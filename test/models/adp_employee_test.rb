# == Schema Information
#
# Table name: adp_employees
#
#  id                  :integer          not null, primary key
#  associate_oid       :string(255)
#  associate_id        :string(255)
#  position_id         :string(255)
#  first_name          :string(255)
#  last_name           :string(255)
#  job_title           :string(255)
#  department_name     :string(255)
#  department_id       :string(255)
#  agent_indicator     :integer
#  hire_date           :date
#  position_start_date :date
#  class_start_date    :date
#  class_end_date      :date
#  trainer             :string(255)
#  uptraining_class    :string(255)
#  compliance_status   :integer
#  deleted             :integer
#  agent_supervisor    :string(255)
#  pod                 :string(255)
#  agent_site          :string(255)
#  client              :string(255)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  salesman_id         :integer
#  npn                 :string(255)
#

require 'test_helper'

class AdpEmployeeTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
