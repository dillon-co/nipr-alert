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

class StateDetail < ApplicationRecord
  belongs_to :license

    def new_table_values
       array_of_new_table_fields = ["associateID varchar(50) DEFAULT NULL",
  "associateOID varchar(16) DEFAULT NULL",
  "givenName varchar(50) DEFAULT NULL",
  "familyName varchar(50) DEFAULT NULL",
  "formattedName varchar(50) DEFAULT NULL",
  "gender char(1) DEFAULT NULL",
  "primaryIndicator varchar(50) DEFAULT NULL",
  "addresslineOne varchar(50) DEFAULT NULL",
  "city varchar(50) DEFAULT NULL",
  "country varchar(50) DEFAULT NULL",
  "zipcode varchar(50) DEFAULT NULL",
  "State varchar(50) DEFAULT NULL",
  "homeWorkLocationCity varchar(50) DEFAULT NULL",
  "homeWorkLocationState varchar(50) DEFAULT NULL",
  "homeWorkLocationZip varchar(50) DEFAULT NULL",
  "homeWorkLocationAddress varchar(50) DEFAULT NULL",
  "homeWorkLocationCode varchar(50) DEFAULT NULL",
  "departmentValue varchar(50) DEFAULT NULL",
  "departmentCode varchar(50) DEFAULT NULL",
  "businessUnit varchar(50) DEFAULT NULL",
  "N_Number varchar(50) DEFAULT NULL",
  "OIGGSA varchar(50) DEFAULT NULL",
  "AgentID varchar(50) DEFAULT NULL",
  "SiebelID varchar(50) DEFAULT NULL",
  "SiebelPin varchar(50) DEFAULT NULL",
  "SiebelPassword varchar(50) DEFAULT NULL",
  "tempPassword varchar(50) DEFAULT NULL",
  "tempToken varchar(50) DEFAULT NULL",
  "NPN varchar(50) DEFAULT NULL",
  "Trainer varchar(45) DEFAULT NULL",
  "TrainingStartDate varchar(45) DEFAULT NULL",
  "TrainingGradDate varchar(45) DEFAULT NULL",
  "TrainingComplianceStatus varchar(45) DEFAULT NULL",
  "capLevel varchar(50) DEFAULT NULL",
  "capDate date DEFAULT NULL",
  "NICE_SkillTeam varchar(50) DEFAULT NULL",
  "phoneNumber varchar(50) DEFAULT NULL",
  "email1 varchar(50) DEFAULT NULL",
  "email2 varchar(50) DEFAULT NULL",
  "positionStatusCode varchar(50) DEFAULT NULL",
  "positionstatusValue varchar(50) DEFAULT NULL",
  "positionreasonCode varchar(50) DEFAULT NULL",
  "positionreasonValue varchar(50) DEFAULT NULL",
  "hireDate date DEFAULT NULL",
  "startDate date DEFAULT NULL",
  "terminationDate date DEFAULT NULL",
  "positionID varchar(50) DEFAULT NULL",
  "PositionOID varchar(45) DEFAULT NULL",
  "groupCode varchar(50) DEFAULT NULL",
  "origionalHireDate date DEFAULT NULL",
  "origionalTerminationDate date DEFAULT NULL",
  "workerStatus varchar(50) DEFAULT NULL",
  "workerType varchar(50) DEFAULT NULL",
  "jobCode varchar(50) DEFAULT NULL",
  "jobValue varchar(50) DEFAULT NULL",
  "reportsToOID varchar(50) DEFAULT NULL",
  "reportsToID varchar(50) DEFAULT NULL",
  "reportsToName varchar(50) DEFAULT NULL"]
    #  PRIMARY KEY (associate_oid)
    # ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

      new_string = array_of_new_table_fields.map do |field|
        items = field.split(' ')
        item = items.first.underscore
        type = items[1]
        if type.split("(").first == "varchar" || type.split("(").first == "char"
          type = "string"
        elsif type.split("(").first == 'tinyint'
          type = "integer"
        end
        "#{item}:#{type}"
      end
      new_string.join(" ")
    end
end
