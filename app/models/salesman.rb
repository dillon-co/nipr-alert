# == Schema Information
#
# Table name: salesmen
#
#  id                  :integer          not null, primary key
#  npn                 :string(255)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  position_id         :string(255)
#  first_name          :string(255)
#  last_name           :string(255)
#  associate_oid       :string(255)
#  associate_id        :string(255)
#  adp_position_id     :string(255)
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
#  username            :string(255)
#  cxp_employee_id     :string(255)
#

require 'csv'
class Salesman < ApplicationRecord
  has_many :states
  has_many :state_agent_appointeds

  def api_path
    "https://pdb-services-beta.nipr.com/pdb-xml-reports/entityinfo_xml.cgi?customer_number=beta83connpt&pin_number=Nipr1234&report_type=1&id_entity=#{self.npn}"
  end

  def grab_info
    res = open(api_path)
    data = Hash.from_xml(res.read)
    return data
  end

  def update_npn_and_get_data(npn)
    self.update(npn: npn)
    update_states_licensing_info
  end

  def update_states_licensing_info
    data = grab_info
    update_name_if_nil(data)
    all_states = data["PDB"]['PRODUCER']['INDIVIDUAL']["PRODUCER_LICENSING"]["LICENSE_INFORMATION"]["STATE"]
    all_states.each do |state_info|
      db_state = self.states.find_or_create_by(name: state_info["name"])
      db_state.save!
      save_states_data(db_state, state_info)
    end
  end

  def save_states_data(state, state_info)
    save_licensing_info(state, state_info["LICENSE"])
    save_appointment_info(state, state_info["APPOINTMENT_INFORMATION"]["APPOINTMENT"])
  end

  def save_licensing_info(state, state_info)
    s_info = downcased(state_info)
    license_info = s_info.except("details")
    license = state.licenses.find_or_create_by(license_num: s_info['license_info'], salesman_id: self.id)
    license.update!(license_info)
    license.save!
    save_license_details(license, [s_info["details"]["DETAIL"]].flatten)
  end

  def save_license_details(license, info)
    info.each do |i|
      license_details = downcased(i)
      deet = license.state_details.find_or_create_by(loa: license_details["loa"])
      deet.update(license_details)
    end
  end

  def save_appointment_info(state, state_info)
    state_info.each do |appt|
      unless appt.is_a?(Array)
        reformatted_state_info = downcased(appt)
        st = state.appointments.find_or_create_by(company_name: reformatted_state_info["company_name"])
        st.update(reformatted_state_info)
      end
    end
  end

  def downcased(data_hash)
    new_hash = {}
    data_hash.keys.each do |k|
      new_hash[k.downcase] = data_hash[k]
    end
    new_hash
  end

  def get_name_info(biographic_data)
    {first_name: biographic_data["NAME_FIRST"].titleize, last_name: biographic_data["NAME_LAST"].titleize}
  end

  def update_name_if_nil(data)
    if first_name == nil
      name_info = get_name_info(data["PDB"]['PRODUCER']['INDIVIDUAL']["ENTITY_BIOGRAPHIC"]["BIOGRAPHIC"])
      self.update(name_info)
    end
  end

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

  def self.get_csv_and_save_data
    array_of_data = self.read_csv
    array_of_data.each do |person|
      self.find_or_create_by(associate_oid: person["associate_oid"]).update(cxp_employee_id: person["cxp_employee_id"], username: person["username"])
    end
  end

  def self.read_csv
    csv_data = CSV.read("#{Rails.root}/../../Downloads/cXp_ID_Table.csv")
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

  def add_needed_states
    self.update(jit_sites_not_appointed_in: get_needed_states.join(", "))
  end

  def get_needed_states
    states_needed_per_site[agent_site.titleize] - states.all.map(&:name)
  end

  def states_needed_per_site
    {"Provo" => ["AK", "AZ", "CO", "HI", "ID", "MT", "NM", "OR", "UT", "WA", "CA", "NV", "VA", "WY"],
      "Sandy" => all_states_names,
      "Memphis" => all_states_names,
      "San Antonio" => ["AR", "ND" "IA", "KS", "NE", "OK", "SD", "TX"],
      "Sunrise" => ["AL", "LA"],
      "Sawgrass" => all_states_names
    }
  end

  def all_states_names
    "AK,AL,AR,AZ,CA,CO,CT,DC,DE,FL,GA,HI,IA,ID,IL,IN,KS,KY,LA,MA,ME,MD,MI,MN,MS,MO,MT,NB,NC,ND,NE,NH,NJ,NM,NV,NY,OH,OK,ON,OR,PA,PR,RI,SC,SD,TN,TX,UT,VA,VT,WA,WI,WV,WY".split(',')
  end  

  def sites_with_just_in_time_states
    {"Provo" =>  ["CA", "NV", "VA", "WY"],
      "Sunrise" => ["GA", "MS", "NC", "SC", "TN"],
      "Sandy" => ["AK", "AR", "CA", "CT", "DE", "DC", "FL", "GA", "HI", "ID", "IA", "KS", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OK", "SC", "SD", "TN", "TX", "VA", "WV", "WY"],
      "Memphis" => ["AK", "AR", "CA", "CT", "DE", "DC", "FL", "GA", "HI", "ID", "IA", "KS", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OK", "SC", "SD", "TN", "TX", "VA", "WV", "WY"],
      "San Antonio" => ["IA", "KS", "NE", "OK", "SD", "TX"],
      "Sawgrass" => ["AK", "AR", "CA", "CT", "DE", "DC", "FL", "GA", "HI", "ID", "IA", "KS", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OK", "SC", "SD", "TN", "TX", "VA", "WV", "WY"]}
  end

  # def self.add_appointed_data_to_agent
  #   appointed_states = 'AK, AR, AZ, CA, CO, CT, DC, DE, FL, GA, HI, IA, ID, IL, IN, KS, KY, LA, MA, MD, ME, MI, MN, MO, MS, MT, NC, ND, NE, NH, NJ, NM, NV, NY, OH, OK, OR, PA, RI, SC, SD, TN, TX, UT, VA, VT, WA, WI, WV, WY'
  #   the_npn = "17319593"
  #   state_liscense_data = "20181031,NULL,20171008,20191031,20180930,20171031,20171008,20181031,20190228,99991231,20181031,20181016,20191031,20181031,20181031,20181031,20181008,20181031,29991231,20181008,99991231,20181031,99991231,20171031,20171031,20180913,20181031,NULL,99991231,20181031,20181031,20171031,20181031,99991231,20191001,20181008,20181031,20181031,NULL,20181031,20181031,NULL,20181031,99991231,20171031,20181031,20181008,20181031,99991231,20190331,20171008,20181031,20181031,20181031"
  #   #This is crappy code
  # end



#################################################################################
  # def find_all_the_values
  #   needed_attributes = ["effective_date",
  #     "expiration_date",
  #     "renewal_submitted_date",
  #     "renewal_confirmed_date",
  #     "appointed_submitted_date",
  #     "appointed_approved_date",
  #     "location_description",
  #     "job_title_description",
  #     "appont_renewal_date",
  #     "active",
  #     "authority_issue_date"]
  #   needed_attributes.map! {|atr| atr.upcase}
  #   puts needed_attributes
  #   values = ga
  #   vals = []
  #   search_hash_for_values(values, needed_attributes, vals)
  #   puts '================='
  #   puts vals.uniq
  # end
  #
  #
  # def search_hash_for_values(h, words, found_words)
  #   fw = found_words
  #   h.keys.each do |k|
  #     # puts "~~~>#{k}<~~~"
  #     if words.include?(k)
  #       puts "#{k} => #{h[k]}"
  #       # puts "\n\nFound #{k}\n\n=================\n#{h[k]}"
  #       fw << k
  #     end
  #     if h[k].is_a?(Hash)
  #       # puts "Searching #{k}\n"
  #       search_hash_for_values(h[k], words, fw)
  #     elsif h[k].is_a?(Array)
  #       h[k].each do |a|
  #         search_hash_for_values(a, words, fw)
  #       end
  #     end
  #   end
  # end
end
