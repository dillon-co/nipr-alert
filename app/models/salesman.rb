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

class Salesman < ApplicationRecord
  has_many :states
  after_create :update_states_licensing_info

  def api_path
    "https://pdb-services-beta.nipr.com/pdb-xml-reports/entityinfo_xml.cgi?customer_number=beta83connpt&pin_number=Nipr1234&report_type=1&id_entity=#{self.npn}"
  end

  def grab_info
    res = open(api_path)
    data = Hash.from_xml(res.read)
    return data
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
