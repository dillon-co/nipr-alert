# == Schema Information
#
# Table name: state_details
#
#  id                   :integer          not null, primary key
#  loa                  :string(255)
#  loa_code             :string(255)
#  status               :string(255)
#  status_reason        :string(255)
#  ce_compliance        :string(255)
#  ce_credits_needed    :string(255)
#  authority_issue_date :date
#  status_reason_date   :date
#  ce_renewal_date      :date
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  license_id           :integer
#

require 'test_helper'

class StateDetailTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
