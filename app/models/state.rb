# == Schema Information
#
# Table name: states
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  salesman_id     :integer
#  adp_employee_id :integer
#

require 'rubyXL'
class State < ApplicationRecord
  belongs_to :salesman, optional: true
  has_many :appointments
  has_many :licenses
  after_create :decide_appointed_or_not

  def asdf
    workbook = RubyXL::Parser.parse("#{Rails.root}/../../Downloads/cxp_reporting.xlsx")
    sheet = workbook[0]
    needed_fields = sheet.select do |row|
      if row[9] != nil
        row if row[9].value == "Y" || row[9].value == "y"
      end
    end
    needed_field_names = needed_fields.map! { |field| field[4].value }
    binding.pry
  end

  def gets_check

  end

  def companies_needed
    ["Aetna Life Ins Company",
      "Coventry Health And Life Ins. Company",
      "First Health Life & Health Insurance Company",
      "Aetna Health And Life Insurance Company",
      "Aetna Health, Inc. (Pa)",
      "Aetna Life Insurance Company",
      "Aetna Health, Inc.",
      "Aetna Health Insurance Company",
      "Coventry Health And Life Insurance Company",
      "Aetna Health, Inc (Pa)",
      "Coventry Health & Life Insurance Company",
      "Coventry Health Care Of Kansas",
      "Coventry Health Care Of Missouri",
      "Coventry Health Care Of Florida",
      "Coventry Health Plan Of Florida",
      "Coventry Health Care Of Georgia",
      "Aetna Health Of Iowa, Inc.",
      "Coventry Health And Life Insurance Co",
      "Coventry Health Care Of Missouri, Inc",
      "Aetna Health, Inc. (A Pennsylvania Corporation)",
      "Aetna Health, Inc",
      "Aetna Health Ins Co Of New York",
      "Aetna Life Ins Co",
      "Aetna Healthassurance Pennsylvania",
      "Aetna Health, Inc.",
      "Dba Coventry Health Care Of The Carolinas",
      "Aetna Health Of Utah, Inc.",
      "Coventry Health Care Of West Virginia",
      "Aetna Health Insurance Company",
      "Aetna Health, Inc.",
      "Coventry Health And Life Insurnce Company",
      "Coventry Health Care Of Nebraska",
      "Aetna Health, Inc. (A Pa Corp)",
      "Coventry Health & Life Ins Co",
      "Aetna Dental, Inc.",
      "Coventry Health Care Of Texas",
      "Coventry Health Care Of Virginia",
      "Coventry Health Care Of De",
      "Aetna Health Of Utah, Inc",
      "Coventry Health Care Of The Carolinas"]
  end

  def decide_appointed_or_not
    appointments.all.each do |a|
      if a.status == "Appointed" && companies_needed.include?(a.company_name)
        self.update(appointed: true)
      end
    end
  end
end


# ["Do you currently reside in Utah?",
#  "Admin Proceeding",
#  "Armed Forces",
#  "I agree to attach expl. statements if any answer is YES",
#  "Bankrupt/Liens",
#  "Bankrupt/Monies Owed",
#  "Child Support Past Due",
#  "Complaint Fine",
#  "Complaint Reported",
#  "Consumer Initiated Complaint",
#  "Convicted Felony",
#  "Convicted Misdemeanor",
#  "Current Investigations",
#  "Delinquent Tax",
#  "Drivers License Revoked",
#  "Employment Contract Termination",
#  "E&O Denied",
#  "Excluded",
#  "Federal Complaint",
#  "Felony/Mis Conviction",
#  "Currently Party to any fraud allegations?",
#  "Insurance Debt",
#  "Legal Discipline",
#  "License Denied",
#  "License Refused",
#  "License Surrendered",
#  "Military Offense",
#  "Misconduct Termination",
#  "Other Complaints",
#  "Agent Signature",
#  "Agent Signature Date",
#  "State or Federal Delinquent Tax",
#  "Supporting Documents",
#  "Surety Denied",
#  "Violation Insurance Law",
#  "Agent Signature Date",
#  "Agent Signature",
#  "Are you a Citizen of the United States?",
#  "Name as it appears on Driver's License",
#  "Drivers License State",
#  "Date of Birth",
#  "Drivers License Number",
#  "Employer 1 City",
#  "Employer 1 Name",
#  "Employer 1 Country",
#  "Employer 1 End Date",
#  "Employment 1 Start Date",
#  "Employer 1 State",
#  "Employer 1 Street",
#  "Employer 1 Position Held",
#  "Gender",
#  "Home Address Street",
#  "Current Address 1 City",
#  "Current Address 1 Date End",
#  "Current Address 1 Date Start",
#  "Home Address Email",
#  "Home Address State",
#  "Current Address 1 Zip",
#  " Agent Signature Date",
#  "Agent Signature",
#  "First Name",
#  "Last Name",
#  "Have you used any other names or aliases in the past?",
#  "Social Security Number"]
