# == Schema Information
#
# Table name: salesmen
#
#  id          :integer          not null, primary key
#  npn         :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  position_id :string(255)
#  first_name  :string(255)
#  last_name   :string(255)
#

require 'test_helper'

class SalesmanTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
