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


require 'csv'
require 'nokogiri'
require 'open-uri'
require 'roo'
require 'roo-xls'
require 'net/ssh'

class Salesman < ApplicationRecord
  has_many :states
  has_many :state_agent_appointeds

  filterrific :default_filter_params => {sorted_by: 'created_at_desc' },
              available_filters:[
                :sorted_by,
                :search_query,
                :with_created_at_gte,
		:is_active,
                :created_before_gte
              ]

  scope :is_active, lambda { |flag|
      return nil if 0 == flag
      where(worker_status: "Active")
  }

  scope :search_query, lambda { |query|
    return nil  if query.blank?
    # condition query, parse into individual keywords
    terms = query.to_s.downcase.split(/\s+/)
    # replace "*" with "%" for wildcard searches,
    # append '%', remove duplicate '%'s
    terms = terms.map { |e|
      (e.gsub('*', '%') + '%').gsub(/%+/, '%')
    }
    # configure number of OR conditions for provision
    # of interpolation arguments. Adjust this if you
    # change the number of OR conditions.
    num_or_conditions = 10
    where(
      terms.map {
        or_clauses = [
          "LOWER(salesmen.first_name) LIKE ?",
          "LOWER(salesmen.given_name) LIKE ?",
          "LOWER(salesmen.last_name) LIKE ?",
          "LOWER(salesmen.family_name) LIKE ?",
          "LOWER(salesmen.reports_to_name) LIKE ?",
          "LOWER(salesmen.agent_site) LIKE ?",
          "LOWER(salesmen.home_work_location_city) LIKE ?",
          "LOWER(salesmen.npn) LIKE ?",
          "LOWER(salesmen.client) LIKE ?",
          "LOWER(salesmen.position_id) LIKE ?"
        ].join(' OR ')
        "(#{ or_clauses })"
      }.join(' AND '),
      *terms.map { |e| [e] * num_or_conditions }.flatten
    )
  }

  scope :with_created_at_gte, lambda { |ref_date|
    date_arr = ref_date.split('/')
    year = date_arr.pop
    new_date = date_arr.unshift(year).join("-").to_date
    where('salesmen.start_date > ?', new_date)
    # where('salesmen.position_start_date BETWEEN ? AND ?', ref_date1, ref_date2)
  }

  scope :created_before_gte, lambda { |ref_date|
    date_arr = ref_date.split('/')
    year = date_arr.pop
    new_date = date_arr.unshift(year).join("-").to_date
     where('salesmen.start_date < ?', new_date)
  }

  scope :sorted_by, lambda { |sort_option|
      # extract the sort direction from the param value.
      direction = (sort_option =~ /desc$/) ? 'desc' : 'asc'
      case sort_option.to_s
      when /^created_at_/
        order("salesmen.created_at #{ direction }")
      when /^position_start_date_/
        order("salesmen.position_start_date #{ direction }")
      when /^last_name_/
        order("LOWER(salesmen.last_name) #{ direction }, LOWER(salesmen.first_name) #{ direction }")
      when /^first_name_/
        order("LOWER(salesmen.first_name) #{ direction }")
      when /^site_/
        order("LOWER(salesmen.site) #{ direction }")
      else
        raise(ArgumentError, "Invalid sort option: #{ sort_option.inspect }")
      end
    }

    def self.options_for_sorted_by
      [
        ['First Name (a-z)', 'first_name_asc'],
        ['Last Name (a-z)', 'last_name_asc'],
        ['Hire date (newest first)', 'created_at_desc'],
        ['Hire date (oldest first)', 'created_at_asc'],
      ]
    end

  def self.search(column)
    unless search[:column] == ''
      where("#{search[:column]} LIKE ?", "%#{search}")
    else
      scoped
    end
  end

  def api_path
    "https://pdb-services.nipr.com/pdb-xml-reports/entityinfo_xml.cgi?customer_number=dcortez&pin_number=p3anutpingpong&report_type=1&id_entity=#{self.npn}"
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

  def self.update_licensing_info_from_batch
    ##Read XML as array,
    establish_connection(:development)
    doc = File.open("#{Rails.root}/pdb_batch.xml") # do |f|
    #    Nokogiri::XML(f)
    doc_hash = Hash.from_xml(doc)
    doc_hash.first.last["SCB_Report_Body"]["SCB_Producer"].each do |a|
      # agent = self.turn_array_to_hash(agent)
      agent = Salesman.create!(npn: a["National_Producer_Number"],
                    first_name: a["Name_Birth"]["First_Name"].titleize,
                    last_name: a["Name_Birth"]["Last_Name"].titleize,
                    agent_site: a["Address"].first["City"].titleize,
                    home_work_location_city: a["Address"].first["City"].titleize)
      aa = agent.save!
      if agent.persisted?
        self.update_batch_agent_state_data(a, agent)
      end
      # else
      #  self.create_agent_with_data(a)
      # end
    end
  end

  def self.update_batch_agent_state_data(agent_data, agent)
    license_data = agent_data["License"].map {|l| l.compact != [] ?  l : nil }.compact
    license_data.each do |state_license|
      state_license = self.turn_array_to_hash(state_license)
      # self.create_licenses_from_batch_with_state(state_license, agent)
      st = agent.states.new(name: state_license["State_Code"], salesman_id: agent.id)
      st.save!
      st.licenses.create!(license_num: state_license["License_Number"],
      date_issue_license_orig: state_license["License_Issue_Date"],
      date_expire_license: state_license["License_Expiration_Date"],
      license_class: state_license["Class"],
      license_class_code: state_license["License_Class_Code"],
      residency_status: state_license["Resident_Indicator"],
      active: state_license["Active"])
      l.save
    end
    self.add_appointments_to_each_state(agent_data, agent)
  end

  def self.create_licenses_from_batch_with_state(state_license, agent)
  end

  def self.turn_array_to_hash(state_license)
    if state_license.is_a?(Array)
      if state_license.count > 1
        state_license = state_license.first
      else
        state_license = state_license.to_h
      end
    end
    return state_license
  end

  def self.add_appointments_to_each_state(agent_data, agent)
    agent_data = self.turn_array_to_hash(agent_data)
    agent.states.all.each do |s|
      if agent_data["Appointment"] != nil
        matching_states = agent_data["Appointment"].select {|appt| appt["State_Code"] == s.name }
        matching_states = matching_states.first
        if matching_states
          matching_states.each do |appoint|
            appoint = self.turn_array_to_hash(appoint)
            s.appointments.create(company_name: appoint["Company_Name"],
                                  fein: appoint["FEIN"],
                                  cocode: appoint["COCODE"],
                                  line_of_authority: appoint["Line_Of_Authority"],
                                  loa_code: appoint["LOA_Code"],
                                  status: appoint["Status"],
                                  termination_reason: appoint["Termination_Reason"],
                                  status_reason_date: appoint["Status_Reason_Date"],
                                  appont_renewal_date: appoint["Renewal_Date"]
                                  )
          end
        end
      end
    end
  end

  def self.create_agent_with_data(agent_data)
    if self.turn_array_to_hash(agent_data["Address"].first)["City"] != nil
      a_site = self.turn_array_to_hash(agent_data["Address"].first)["City"].titleize
    else
      a_site = false
    end
    if a_site
      a = self.create!(first_name: agent_data["Name_Birth"]["First_Name"].titleize,
                   last_name: agent_data["Name_Birth"]["Last_Name"].titleize,
                   agent_site: a_site,
                   home_work_location_city: a_site)
    else
      a = self.create!(first_name: agent_data["Name_Birth"]["First_Name"].titleize,
      last_name: agent_data["Name_Birth"]["Last_Name"].titleize)
    end
    a.save!
    if a.present?
      self.update_batch_agent_state_data(agent_data, a)
    end
  end

  def update_states_licensing_info
    data = grab_info
    update_name_if_nil(data)
    all_states = data["PDB"]['PRODUCER']['INDIVIDUAL']["PRODUCER_LICENSING"]["LICENSE_INFORMATION"]["STATE"]
    all_states.each do |state_info|
      begin
        db_state = self.states.find_or_create_by(name: state_info["name"])
        db_state.save!
        save_states_data(db_state, state_info)
      rescue => e
        puts e
        next
      end
    end
  end

  def save_states_data(state, state_info)
    save_licensing_info(state, state_info["LICENSE"])
    save_appointment_info(state, state_info["APPOINTMENT_INFORMATION"]["APPOINTMENT"])
  end

  def save_licensing_info(state, state_info)
    s_info = downcased(state_info) unless s_info.is_a?(Array)
    unless s_info == nil
      license_info = s_info.except("details")
      license = state.licenses.find_or_create_by(license_num: s_info['license_info'], salesman_id: self.id)
      license_info["date_updated"] = Date.strptime(license_info["date_updated"], "%m/%d/%Y") unless license_info["date_updated"] == nil
      license_info["date_issue_license_orig"] = Date.strptime(license_info["date_issue_license_orig"], "%m/%d/%Y") unless license_info["date_issue_license_orig"] == nil
      license_info["date_expire_license"] = Date.strptime(license_info["date_expire_license"], "%m/%d/%Y") unless license_info["date_expire_license"] == nil
      license.update!(license_info)
      license.save!
      save_license_details(license, [s_info["details"]["DETAIL"]].flatten)
    end
  end

  def save_license_details(license, info)
    info.each do |i|
      unless i.is_a?(Array)
        license_details = downcased(i)
        deet = license.state_details.find_or_create_by(loa: license_details["loa"])
        deet.update(license_details)
      end
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
    unless data_hash.is_a?(Array)
      new_hash = {}
      data_hash.keys.each do |k|
        new_hash[k.downcase] = data_hash[k]
      end
      new_hash
    end
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

  def self.get_data_from_sandbox_reporting
    # stag_adp = StagAdpEmployeeinfo.all.as_json
    #stag_adp = ActiveRecord::Base.connection.execute(sql).as_json
    #appointment_data = StagAgentAppointed.all.as_json
    #appointment_data = ActiveRecord::Base.connection.execute(sql2).as_json
    # @hostname, @username, @password  = "aurora-ods.cluster-clc62ue6re4n.us-west-2.rds.amazonaws.com", "sgautam", "6N1J$rCFU(PxmU[I"
    # open_up_table = 'USE Sandbox_Reporting'
    # sql = "select * from stag_adp_employeeinfo"
    # sql2 = "select * from stag_agent_appointed"
    @hostname = "aurora-ods.cluster-clc62ue6re4n.us-west-2.rds.amazonaws.com"
    @username = "sgautam"
    @password = "6N1J$rCFU(PxmU[I"
    # 10.0.35.34
    mr_c = establish_connection(
      :adapter => 'mysql2',
      :database => 'Sandbox_Reporting',
      :host => @hostname,
      :username => @username,
      :password => @password,
      :port => '3306'
    )
    results = mr_c.connection.execute("select * from stag_adp_employeeinfo")
    r_fields = results.fields.map{|f| f.underscore }
    stag_adp = results.map {|a| Hash[r_fields.zip(a)] }
    # appointment_results = mr_c.connection.execute("select * from stag_agent_appointed")
    # a_fields = appointment_results.fields.map{|f| f.underscore }
    # appointment_data = appointment_results.map {|a| Hash[a_fields.zip(a)]}
    establish_connection(:development)
    self.save_stag_adp_employeeinfo(stag_adp)
    # self.save_aetna_appointment_data(appointment_data)
  end

  # stag_adp = external_db.execute(sql).as_json
  # appointment_data = external_db.execute(sql2).as_json
  def self.save_stag_adp_employeeinfo(stag_adp)
    stag_adp.each do |employee|
      e = self.find_by(npn: employee["npn"])
      if e.present?
        e.update!(employee)
      else
	      puts employee
        n_e = self.create!(employee)
        # n_e.update_states_licensing_info
      end
    end
  end

  def self.save_aetna_appointment_data(a_data)
    a_data.each do |agent|
      s = Salesman.find_or_create_by(npn: agent["npn"])
      agent.keys.each do |k|
        if k.to_s.length == 2
          s.states.find_or_create_by(name: k).update(appointment_date: k)
        end
      end
    end
  end

  def self.connect_to_sandbox_reporting
    @hostname = "aurora-ods.cluster-clc62ue6re4n.us-west-2.rds.amazonaws.com"
    @username = "sgautam"
    @password = "6N1J$rCFU(PxmU[I"
    # 10.0.35.34
    @conection = establish_connection(
      :adapter => 'mysql2',
      :database => 'Sandbox_Reporting',
      :host => @hostname,
      :username => @username,
      :password => @password,
      :port => '3306'
    )
    return @connection
   end



  # def self.connect_to_localhost
  #   @hostname = "localhost"
  #   @username = "dilloncortez"
  #   @password = "slop3styl3"
  #   sql = "Select * from Video"
  #   # 10.0.35.34
  #   ActiveRecord::Base.establish_connection(
  #     :adapter => 'postgresql',
  #     :database => 'velvi_videos_development',
  #     :host => @hostname,
  #     :username => @username,
  #     :password => @password
  #   )
  #   # ActiveRecord::Base.connection.tables.each do |table|
  #   #   next if table.match(/\Aschema_migrations\Z/)
  #   #   klass = table.singularize.camelize.constantize
  #   #   puts "#{klass.name} has #{klass.count} records"
  #   # end
  # end


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

  def update_agent_site
    site = self.home_work_location_city
    self.update(agent_site: site)
  end

  def add_needed_states
    self.update(jit_sites_not_appointed_in: get_needed_states.join(", "))
  end

  def get_needed_states
      # @check_or_naw = @needed_states - @can_sell_states
    active_states = states.includes(:appointments).select {|s| s.appointments.count > 0}.compact
    can_sell_states = [active_states.map(&:name), jit_states].flatten.uniq.compact
    if states_needed_per_site != nil
        states_needed_per_site - can_sell_states
     else
    	all_states_names - states.all.map(&:name)
     end
   end

   def array_of_states_needed
     states_needed_per_site - self.states.all.map(&:name)
   end

   def states_needed_per_site
     if self.client == "Anthem"
       anthem_states
     else [self.agent_site, self.home_work_location_city].compact.uniq
       case
       when"Provo"
         ["AK", "AZ", "CO", "HI", "ID", "MT", "NM", "OR", "UT", "WA", "CA", "NV", "VA", "WY"]
       when "Sandy"
         sandy_states
       when "Memphis"
         all_states_names
       when "San Antonio"
         ["AR", "ND", "IA", "KS", "NE", "OK", "SD", "TX"]
       when "Sunrise"
         ["AL","LA","GA","MS","NC","SC","TN"]
       when "Sawgrass"
         all_states_names
       when "Roy"
         all_states_names
       else
         all_states_names
       end
     end
   end

   def sandy_states
     %w(AL AZ CO IL IN KY LA MT OH OR PA PR RI UT VT WA WI AK AR CA CT DE DC FL GA HI ID IA KS ME MD MA MI MN MS MO NE NV NH NJ NM NY NC ND OK SC SD TN TX VA WV WY)
   end

  def all_states_names
    ["AK",
    "AL",
    "AR",
    "AZ",
    "CA",
    "CO",
    "CT",
    "DC",
    "DE",
    "FL",
    "GA",
    "HI",
    "IA",
    "ID",
    "IL",
    "IN",
    "KS",
    "KY",
    "LA",
    "MA",
    "MD",
    "ME",
    "MI",
    "MN",
    "MO",
    "MS",
    "MT",
    "NC",
    "ND",
    "NE",
    "NH",
    "NJ",
    "NM",
    "NV",
    "NY",
    "OH",
    "OK",
    "OR",
    "PA",
    "RI",
    "SC",
    "SD",
    "TN",
    "TX",
    "UT",
    "VA",
    "VT",
    "WA",
    "WI",
    "WV",
    "WY"]
  end

  def jit_states
    ["AK",
     "AR",
     "CA",
     "CT",
     "DE",
     "DC",
     "FL",
     "GA",
     "HI",
     "ID",
     "IA",
     "KS",
     "ME",
     "MD",
     "MA",
     "MI",
     "MN",
     "MS",
     "MO",
     "NE",
     "NV",
     "NH",
     "NJ",
     "NM",
     "NY",
     "NC",
     "ND",
     "OK",
     "SC",
     "SD",
     "TN",
     "TX",
     "VA",
     "WV",
     "WY"]
  end

  def sites_with_just_in_time_states
    { "Provo" =>  jit_states,
      "Sunrise" => jit_states,
      "Sandy" => jit_states,
      "Memphis" => jit_states,
      "San Antonio" => jit_states,
      "Sawgrass" => jit_states}
  end

  def self.update_npns_from_spread_sheet
    xl = Roo::Spreadsheet.open("#{Rails.root}/new_npn_numbers.xls", extension: :xls)
    sheet = xl.sheet(0).to_a
    sheet.to_a.shift
    sheet.each do |row|
      begin
        if row[2] == "Active" && row[3] != ""
          sman = self.find_or_create_by(npn: row[3])
          sman.update_states_licensing_info
        end
      rescue
        next
      end
    end
  end

  def self.as
    self.update_npns_from_spread_sheet
  end

  def get_client
    cli_arr = self.states.includes(:appointments).all.map { |s| s.appointments.all.map {|apt| apt.company_name} }.flatten.uniq
    split_clients = cli_arr.join(" ").split(" ")
    if split_clients.include?("Aetna") && split_clients.include?("Anthem")
      self.update(client: "Carefree")
    elsif split_clients.include?("Aetna")
      self.update(client: "Aetna")
    elsif split_clients.include?("Anthem")
      self.update(client: "Anthem")
    end
  end

  def anthem_states
     %w(CA
        CO
        CT
        GA
        IN
        KS
        KY
        ME
        MD
        MO
        NH
        NV
        NY
        OH
        VA
        WI)
  end

  def self.update_clients
    self.all.each do |s|
      if s.department_value.present?
        d_v = s.department_value.split(": ").last.split(" ").first
        s.update(client: d_v)
      end
    end
  end
end
