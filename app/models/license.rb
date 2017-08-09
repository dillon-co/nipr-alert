# == Schema Information
#
# Table name: licenses
#
#  id                         :integer          not null, primary key
#  salesman_id                :integer
#  producer_id                :integer
#  license_certification_code :string(255)
#  license_submitted_date     :date
#  license_certification_id   :string(255)
#  effective_date             :date
#  expiration_date            :date
#  renewal_submitted_date     :date
#  renewal_confirmed_date     :date
#  appointed_submitted_date   :date
#  appointed_approved_date    :date
#  location_description       :string(255)
#  job_title_description      :string(255)
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null



class License < ApplicationRecord
  belongs_to :salesman
  belongs_to :state
  has_many :state_details
end
