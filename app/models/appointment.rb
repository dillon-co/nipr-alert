# == Schema Information
#
# Table name: appointments
#
#  id                  :integer          not null, primary key
#  company_name        :string(255)
#  fein                :string(255)
#  cocode              :string(255)
#  line_of_authority   :string(255)
#  loa_code            :string(255)
#  status              :string(255)
#  termination_reason  :string(255)
#  status_reason_date  :date
#  appont_renewal_date :date
#  agency_affiliations :string(255)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  state_id            :integer
#  county_code         :string(255)
#

class Appointment < ApplicationRecord
  belongs_to :state
end
