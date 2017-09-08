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

class AdpEmployee < ApplicationRecord
  has_many :salesman
  has_many :states

  def self.read_csv
    csv_data = CSV.read("#{Rails.root}/../../Downloads/adp_sample_data.csv")
    all_data_as_array_of_hashes, data_types = [], csv_data.shift
    csv_data.each do |row|
      all_data_as_array_of_hashes << self.reformat_row_to_hash(row, data_types)
    end
    all_data_as_array_of_hashes
  end

  def self.reformat_row_to_hash(row, data_types)
    hashie = {}
    row.each_with_index do |item, row_index|
      unless data_types[row_index] == 'created' || data_types[row_index] == 'last_updated'
        hashie["#{data_types[row_index]}"] = item
      end
    end
    hashie
  end

  def self.save_csv_data(data_hash_array)
    self.create!(data_hash_array)
  end

  def self.get_employee_data_and_save
    data_hash_array = self.read_csv
    self.save_csv_data(data_hash_array)
  end

  def self.as
    #This is a command line method that runs the current method needed for debugging, short to speed up dev time
    # binding.pry
    self.get_employee_data_and_save
    # binding.pry
  end

  def get_npn(ssn)
    "https://pdb-services-beta.nipr.com/pdb-xml-reports/hitlist_xml.cgi?customer_number=beta83connpt&pin_number=Nipr1234&report_type=2&ssn=#{ssn}&name_last=smith&name_first=john"
  end

  def update_npn_and_get_data(npn)

  end




  # def api_path
  #   "https://pdb-services-beta.nipr.com/pdb-xml-reports/entityinfo_xml.cgi?customer_number=beta83connpt&pin_number=Nipr1234&report_type=1&id_entity=#{self.npn}"
  # end
  #
  # def grab_info
  #   res = open(api_path)
  #   data = Hash.from_xml(res.read)
  #   return data
  # end
  #
  # def update_states_licensing_info
  #   data = grab_info
  #   update_name_if_nil(data)
  #   all_states = data["PDB"]['PRODUCER']['INDIVIDUAL']["PRODUCER_LICENSING"]["LICENSE_INFORMATION"]["STATE"]
  #   all_states.each do |state_info|
  #     db_state = self.states.find_or_create_by(name: state_info["name"])
  #     db_state.save!
  #     save_states_data(db_state, state_info)
  #   end
  # end
  #
  # def save_states_data(state, state_info)
  #   save_licensing_info(state, state_info["LICENSE"])
  #   save_appointment_info(state, state_info["APPOINTMENT_INFORMATION"]["APPOINTMENT"])
  # end
  #
  # def save_licensing_info(state, state_info)
  #   s_info = downcased(state_info)
  #   license_info = s_info.except("details")
  #   license = state.licenses.find_or_create_by(license_num: s_info['license_info'], salesman_id: self.id)
  #   license.update!(license_info)
  #   license.save!
  #   save_license_details(license, [s_info["details"]["DETAIL"]].flatten)
  # end
  #
  # def save_license_details(license, info)
  #   info.each do |i|
  #     license_details = downcased(i)
  #     deet = license.state_details.find_or_create_by(loa: license_details["loa"])
  #     deet.update(license_details)
  #   end
  # end
  #
  # def save_appointment_info(state, state_info)
  #   state_info.each do |appt|
  #     unless appt.is_a?(Array)
  #       reformatted_state_info = downcased(appt)
  #       st = state.appointments.find_or_create_by(company_name: reformatted_state_info["company_name"])
  #       st.update(reformatted_state_info)
  #     end
  #   end
  # end
  #
  # def downcased(data_hash)
  #   new_hash = {}
  #   data_hash.keys.each do |k|
  #     new_hash[k.downcase] = data_hash[k]
  #   end
  #   new_hash
  # end
  #
  # def get_name_info(biographic_data)
  #   {first_name: biographic_data["NAME_FIRST"].titleize, last_name: biographic_data["NAME_LAST"].titleize}
  # end
  #
  # def update_name_if_nil(data)
  #   if first_name == nil
  #     name_info = get_name_info(data["PDB"]['PRODUCER']['INDIVIDUAL']["ENTITY_BIOGRAPHIC"]["BIOGRAPHIC"])
  #     self.update(name_info)
  #   end
  # end



end
