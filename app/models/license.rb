# == Schema Information
#
# Table name: licenses
#
#  id                      :integer          not null, primary key
#  salesman_id             :integer
#  license_num             :string(255)
#  date_updated            :date
#  date_issue_license_orig :date
#  date_expire_license     :date
#  license_class           :string(255)
#  license_class_code      :string(255)
#  residency_status        :string(255)
#  active                  :string(255)
#  adhs                    :string(255)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  state_id                :integer
#

class License < ApplicationRecord
  belongs_to :salesman
  belongs_to :state
  has_many :state_details
end
