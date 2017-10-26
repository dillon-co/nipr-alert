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
     licensed_states = self.states.all.select do |s|
       s.licenses.count > 0 && s.licenses.last.active == 'Yes' && s.appointments.count > 0
     end
     licensed_states.count > 0 ? licensed_states_names = licensed_states.map(&:name) : licensed_states_names = []
     states_needed_per_site - licensed_states.map(&:name)
   end

   def states_needed_per_site
     if self.client == "Anthem"
       anthem_states
     elsif self.client == 'CareSource'
       %w(OH KY IN UT)
     else
       case [self.agent_site, self.home_work_location_city].compact.uniq.first
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

   def rts_jit_states
     states.all.select {|st| st.licenses.count > 0 && st.licenses.last.active == "Yes" }.map(&:name) - jit_states
   end

   def all_rts_states
     active_states = states.all.select {|s| s.licenses.count > 0 && s.licenses.last.active == "Yes"}
     appointed_active_states = active_states.select {|s| s.appointments.count > 0}
     active_jit_states = active_states.select {|s| jit_states.include?(s.name)}
     return [appointed_active_states, active_jit_states].flatten.compact.uniq.map(&:name)
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
    if self.client == "Aetna"
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
     else
       []
     end
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


  def companies_needed
    ["Aetna Life Ins Company",
      "Coventry Health And Life Ins. Company",
      "First Health Life & Health Insurance Company",
      "Aetna Health And Life Insurance Company",
      "Aetna Health Inc. (Pa)",
      "Aetna Life Insurance Company",
      "Aetna Health Inc.",
      "Aetna Health Insurance Company",
      "Coventry Health And Life Insurance Company",
      "Aetna Health Inc (Pa)",
      "Coventry Health & Life Insurance Company",
      "Coventry Health Care Of Kansas",
      "Coventry Health Care Of Missouri",
      "Coventry Health Care Of Florida",
      "Coventry Health Plan Of Florida",
      "Coventry Health Care Of Georgia",
      "Aetna Health Of Iowa Inc.",
      "Coventry Health And Life Insurance Co",
      "Coventry Health Care Of Missouri Inc",
      "Aetna Health Inc. (A Pennsylvania Corporation)",
      "Aetna Health Inc",
      "Aetna Health Ins Co Of New York",
      "Aetna Life Ins Co",
      "Aetna Healthassurance Pennsylvania",
      "Aetna Health Inc.",
      "Dba Coventry Health Care Of The Carolinas",
      "Aetna Health Of Utah Inc.",
      "Coventry Health Care Of West Virginia",
      "Aetna  Health  Insurance  Company",
      "Aetna Health  Inc.",
      "Coventry Health And Life Insurnce Company",
      "Coventry Health Care Of Nebraska",
      "Aetna Health Inc. (A Pa Corp)",
      "Coventry Health & Life Ins Co",
      "Aetna Dental Inc.",
      "Coventry Health Care Of Texas",
      "Coventry Health Care Of Virginia",
      "Coventry Health Care Of De",
      "Aetna Health Of Utah Inc",
      "Coventry Health Care Of The Carolinas"]
  end

  def appointed_states
    appointed_states = self.states.includes(:appointments).all
    appointed_states.map do|s|
      s.appointments.all.select do |a|
        a.map
      end
    end
  end

  def self.asdfg
    appt_names = self.where(client: "Aetna").map do |agent|
      agent.states.all.each do |state|
        state.appointments.all.map(&:company_name)
      end
    end
    appt_names.flatten.uniq
  end
end

["Aetna Life Ins Company", "Care Improvement Plus Of Texas Insurance Company", "Care Improvement Plus South Central Insurance Company", "Coventry Health And Life Ins. Company", "First Health Life & Health Insurance Company", "Provident Life & Accident Ins Company", "Symphonix Health Insurance, Inc.", "Unitedhealthcare Insurance Company", "Unitedhealthcare Of Alabama Inc", "Unitedhealthcare Of The Midlands, Inc.", "Unum Life Ins Co Of America", "Provident Life & Accident Insurance Company", "Unitedhealthcare Of Arkansas, Inc.", "Unum Life Insurance Company Of America", "American Family Life Assurance Company Of Columbus", "Humanadental Insurance Company", "Provident Life And Accident Insurance Company", "Humana Insurance Company", "Medica Healthcare Plans, Inc.", "Preferred Care Partners, Inc.", "Sierra Health And Life Insurance Company, Inc.", "Care Improvement Plus South Insurance Company", "Cigna Healthcare Of Georgia, Inc.", "Healthspring Life And Health Insurance Company, Inc.", "Humana Benefit Plan Of Illinois, Inc.", "Humana Employers Health Plan Of Georgia, Inc", "Lincoln National Life Insurance Company", "Symphonix Health Insurance, Inc", "Unitedhealthcare Of Georgia, Inc.", "Unitedhealthcare Plan Of The River Valley, Inc.", "Provident Life & Accident Insurance Co", "Aetna Health And Life Insurance Company", "Aetna Health Inc. (Pa)", "Aetna Life Insurance Company", "Anthem Life Insurance Company", "Continental Life Insurance Company Of Brentwood Tennessee", "Dental Concern Inc. (The)", "Humana Health Plan, Inc.", "Humana Insurance Company Of Kentucky", "Humana Medical Plan, Inc.", "Humana Wisconsin Health Organization Insurance Corporation", "Unitedhealthcare Of Ohio, Inc.", "Unitedhealthcare Of Wisconsin, Inc.", "Aetna Health Inc.", "Aetna Health Insurance Company", "Coventry Health And Life Insurance Company", "Gerber Life Insurance Company", "Humana Health Benefit Plan Of Louisiana, Inc.", "Unitedhealthcare Of Louisiana, Inc.", "Anthem Health Plans Of Maine Inc.", "Arcadian Health Plan Inc", "Sierra Health And Life Insurance Company Inc.", "Blue Care Network Of Michigan", "Blue Cross Blue Shield Of Michigan Mutual Insurance Company", "Humana Medical Plan Of Michigan, Inc.", "Unitedhealthcare Community Plan, Inc.", "Healthspring Of Tennessee, Inc.", "Cigna Healthcare Of North Carolina, Inc.", "Unitedhealthcare Insurance Company Of The River Valley", "Unitedhealthcare Of North Carolina, Inc.", "Americhoice Of New Jersey, Inc", "Oxford Health Plans (New Jersey) Inc", "Health Plan Of Nevada Incorporated", "Pacificare Of Nevada Inc", "Care Improvement Plus Of Texas Ins Co", "Care Improvement Plus South Central Ins Co", "First Unum Life Ins Co", "Oxford Health Plans Ny Inc", "Provident Life And Casualty Ins Co", "Unitedhealthcare Ins Co Of New York", "Unitedhealthcare Of New York Inc", "Aetna Health Inc (Pa)", "Community Insurance Company", "Compbenefits Insurance Company", "Humana Health Plan Of Ohio Inc", "Symphonix Health Insurance Inc", "Unitedhealthcare Of Ohio Inc", "Unitedhealthcare Of Oklahoma, Inc.", "Healthassurance Pennsylvania, Inc.", "Oxford Health Plans (Nj), Inc.", "Unitedhealthcare Of New England, Inc.", "Unitedhealthcare Of Pennsylvania, Inc.", "Provident Life And Accident Ins Co", "Provident Life & Accident Ins Co", "Cariten Health Plan Inc.", "Cigna Health And Life Insurance Company", "Unitedhealthcare Plan Of The River Valley, Inc", "Denticare, Inc.", "Healthspring Life & Health Insurance Company, Inc.", "Humana Health Plan Of Texas, Inc.", "Physicians Health Choice Of Texas, Llc", "Unitedhealthcare Benefits Of Texas, Inc.", "Unitedhealthcare Community Plan Of Texas, L.L.C.", "Sierra Health & Life Insurance Company, Inc", "United Healthcare Of Utah Inc", "Unitedhealthcare Of The Mid-Atlantic, Inc.", "Provident Life And Accident Insurance Company  The", "Unitedhealthcare Of Washington Inc", "Care Improvement Plus Wisconsin Insurance Company", "Coventry Health & Life Insurance Company", "Coventry Health Care Of Kansas, Inc.", "Coventry Health Care Of Missouri, Inc.", "Coventry Health Care Of Florida, Inc.", "Coventry Health Plan Of Florida, Inc.", "Coventry Health Care Of Georgia,Inc.", "Aetna Health Of Iowa Inc.", "Coventry Health And Life Insurance Co", "Coventry Health Care Of Missouri Inc", "First Health Life And Health Insurance Company", "Aetna Health Inc. (A Pennsylvania Corporation)", "Aetna Health Inc", "Aetna Health Ins Co Of New York", "Aetna Life Ins Co", "Cambridge Life Ins Co", "Aetna Healthassurance Pennsylvania, Inc.", "Healthamerica Pennsylvania, Inc.", "Aetna Health Inc., Dba Coventry Health Care Of The Carolinas, Inc.", "Aetna Health Of Utah Inc.", "Coventry Health Care Of West Virginia, Inc.", "Continental Life Insurance Co Of Brentwood Tn", "Continental Life Insurance Company Of Brentwood, Tennessee", "Aetna  Health  Insurance  Company", "Aetna Health  Inc.", "Coventry Health And Life Insurnce Company", "Innovation  Health  Insurance  Company", "Innovation Health Plan Inc.", "American Continental Insurance Company", "Continental Life Ins. Co. Of Brentwood, Tennessee", "Coventry Health Care Of Nebraska, Inc.", "Continental Life Insurance Company Of Brentwood Tennesee", "First Health Life & Health Ins Co", "Continental Life Insurance Company Of Brentwood, Tn", "Aetna Health Inc. (A Pa Corp)", "Continental Life Insurance Company Of Brentwood, Tenn.", "Continental Life Insurance Company Of Brentwood, Tennesee", "Continental Life Ins Co Of Brentwood, Tennessee", "Coventry Health & Life Ins Co", "Aetna Dental Inc.", "Coventry Health Care Of Texas, Inc.", "Texas Health + Aetna Health Insurance Company", "Texas Health + Aetna Health Plan Inc.", "Coventry Health Care Of Virginia, Inc.", "Innovation Health Insurance Company", "Innovation Health Plan, Inc.", "Coventry Health Care Of De, Inc.", "Continental Life Insurance Company Of Brentwood Tn", "Aetna Health Of Utah Inc", "Healthamerica Pennsylvania Inc", "Kanawha Insurance Company", "American Dental Providers Of Arkansas, Inc. D/B/A Compbenefits", "Humana Health Plan, Inc", "Compbenefits Dental, Inc.", "Coventry Health Care Of The Carolinas, Inc.", "Humana Health Plan Incorporated", "Humana Ins Co Of New York", "Kanawha Ins Co", "Humana Medical Plan Of Utah Inc", "Continental Life Ins Co Of Brentwood", "Healthspring Of Alabama Inc", "Wellcare Health Insurance Company Of Kentucky, Inc.", "Anthem Blue Cross Life And Health Insurance Company", "Health Net Life Insurance Company", "Loyal American Life Insurance Company", "Medco Containment Life Insurance Company", "Bravo Health Mid-Atlantic, Inc.", "Blue Cross And Blue Shield Of Georgia, Inc.", "Blue Cross Blue Shield Healthcare Plan Of Georgia, Inc.", "Silverscript Insurance Company", "Cigna Healthcare Of St Louis, Inc.", "Cigna Health & Life Insurance Company", "Humana Health Plan Of Ohio Inc.", "Wellcare Prescription Insurance, Inc.", "Humana Benefit Plan Of Illinois Inc", "Cigna Health And Life Ins Co", "Humana Health Co Of New York Inc", "Hcsc Insurance Services Company", "Health Care Service Corporation, A Mutual Legal Reserve Company", "Bravo Health Pennsylvania, Inc.", "Selectcare Health Plans, Inc.", "Selectcare Of Texas, Inc.", "Humana Dental Insurance Company", "Cigna Health And  Life Insurance Company", "Cha Hmo, Inc.", "Unitedhealthcare Of The Midwest, Inc.", "Pacificare Of Colorado Inc", "Humana Regional Health Plan, Inc", "Humana Medical Plan Of Pennsylvania, Inc.", "Arcadian Health Plan, Inc.", "Aaa Life Insurance Company", "Bankers Life & Casualty Company", "Colonial Life & Accident Insurance Company", "Colonial Penn Life Insurance Company", "Unitedhealthcare Of Oregon Inc", "Athene Annuity And Life Company", "Equitable Life & Casualty Insurance Company", "Medico Insurance Company", "Connecticut General Life Insurance Company", "Pacificare Life And Health Insurance Company", "Bravo Health Insurance Company, Inc", "Unicare Life & Health Insurance Company", "United World Life Insurance Company", "Pennsylvania Life Insurance Company", "United Of Omaha Life Insurance Company", "Healthplus Insurance Company", "Healthplus Of Michigan, Inc", "Bcbsm Inc", "Blue Plus", "Mii Life, Incorporated", "Blue Cross And Blue Shield Of North Carolina", "Sterling Life Insurance Company", "Anthem Insurance Companies Inc", "Consumers Life Insurance Company", "Medical Mutual Of Ohio", "Bravo Health Insurance Company, Inc.", "Wellcare Prescription Insurance Inc", "Blue Cross And Blue Shield Of Kansas, Inc.", "Unicare Life & Health Insurance Co", "Anthem Health Plans Of Kentucky, Inc.", "Anthem Health Plans Of Nh, Inc. (Dba Anthem Blue Cross And Blue Shield", "Empire Healthchoice Assur Inc", "Unicare Life & Health Ins Co", "Anthem Health Plans Of Virginia, Inc.", "Anthem Insurance Companies, Inc.", "Healthkeepers, Inc.", "Blue Cross Blue Shield Of Wisconsin", "Compcare Health Services Insurance Corporation", "Kanawha Insruance Company", "Greater Georgia Life Insurance Company", "Wellcare Of Georgia, Inc.", "Wellcare Prescription Insurance Company, Inc.", "Mutual Of Omaha Insurance Company", "Wellcare Health Plans Of New Jersey, Inc.", "Wellcare Of New York Inc", "Wellcare Prescription Ins Inc", "Wellcare Of Ohio Inc", "Wellcare Of Texas, Inc.", "Reliastar Life Insurance Company", "Ehealthinsurance Services Inc", "Capitol County Mutual Fire Insurance Company", "Reliable Life Insurance Company, The", "Constitution Life Insurance Company", "Marquette National Life Insurance Company", "Transamerica Premier Life Insurance Company", "United Teacher Associates Insurance Company", "Pacificare Life & Health Insurance Co", "Pacificare Life Assurance Company", "Unison Health Plan Of Tennessee, Inc.", "Unitedhealthcare Of Tennessee, Inc.", "Allianz Life Insurance Company Of North America", "American National Insurance Company", "Assurity Life Insurance Company", "Metropolitan Life Insurance Company", "North American Company For Life And Health Insurance", "Ohio National Life Assurance Corporation", "Protective Life Insurance Company", "Banner Life Insurance Company", "Pruco Life Insurance Company", "Family Heritage Life Insurance Company Of America", "Individual Assurance Company, Life, Health & Accident", "Northwestern Mutual Life Insurance Company, The", "Humana Health Insurance Company Of Florida, Inc.", "Cha Hmo Inc", "American Income Life Insurance Company", "Government Personnel Mutual Life Ins Co", "Sunshine State Health Plan, Inc.", "Government Personnel Mutual Life Insurance Company", "Omaha Insurance Company", "Blue Cross And Blue Shield Of Texas, A Division Of Health Care Service Corporation", "Molina Healthcare Of Texas, Inc.", "Time Insurance Company", "Combined Insurance Company Of America", "Windsor Health Plan, Inc.", "Hcc Life Insurance Company", "Individual Assurance Co Life Health & Ac", "National Health Ins Company", "Unified Life Insurance Company", "Kaiser Permanente Insurance Company", "National Health Insurance Company", "Companion Life Insurance Company", "Kaiser Foundation Health Plan Of The Mid-Atlantic", "National Health Insurance Co", "Integon Indemnity Corporation", "Family Life Insurance Company", "Fidelity Life Association, A Legal Reserve Life Insurance Company", "Kaiser Foundation Health Plan Of Georgia, Inc.", "Kaiser Foundation Health Plan, Inc. Hawaii Region", "Reserve National Insurance Company", "Individual Assurance Co,Life,Health & Accident", "National Health Ins Co", "Fidelity Life Association A Legal Reserve Life Insurance Company", "Kaiser Foundation Health Plan Of The Mid-Atlantic States, Inc.", "Connextions Hci Llc", "Primerica Life Insurance Company", "Farmers New World Life Insurance Company", "New York Life Insurance And Annuity Corporation", "New York Life Insurance Company", "Medco  Containment Life Insurance Company", "American Retirement Life Insurance Company", "Harmony Health Plan, Inc.", "Medco Containment Life Insurance Co", "Medico Corp Life Insurance Company", "Priority Health", "Priority Health Insurance Company", "Geisinger Health Plan", "Geisinger Quality Options, Inc.", "Silverscript Insurance Co.", "Medco Containment Ins Co Of New York", "Silverscript Ins Co", "Geisinger Indemnity Insurance Company", "Polish Falcons Of America", "Cigna Healthcare Of South Carolina, Inc.", "Athene Annuity & Life Assurance Company", "National Union Fire Ins Company Of Pittsburgh", "Transamerica Life Insurance Company", "Chesapeake Life Insurance Company", "Compbenefits Company", "Healthspring Of Florida, Inc", "National Union Fire Insurance Co. Of Pittsburgh, Pa", "National Union Fire Insurance Company Of Pittsburgh, Pa.", "Ace American Insurance Company", "American General Life Insurance Co", "Federal Insurance Company", "Global Contact Services -000", "Minnesota Life Insurance Company", "National Union Fire Insurance Company Of Pittsburgh, Pennsylvania", "Stonebridge Life Insurance Company", "Tpusa Inc -000", "Union Security Insurance Company", "National Union Fire Insurance Company Of Pittsburgh Pa", "Symphonix Health Insurance , Inc.", "American International Life Assur Co Of New York", "National Union Fire Ins Co Of Pittsburgh Pa", "National Union Fire Insurance Company Of Pittsburgh, Pa", "Blue Cross & Blue Shield Of Florida, Inc.", "Celtic Insurance Company", "Florida Combined Life Insurance Company, Inc", "Golden Rule Insurance Company", "Health Options, Inc.", "Molina Healthcare Of Florida, Inc.", "Chesapeake Life Insurance Company, The", "American Family Life Assurance Co Of Columbus", "Chesapeake Life Ins Co", "All Savers Insurance Company", "Amerigroup Texas, Inc.", "Oscar Insurance Company Of Texas", "Superior Healthplan, Inc.", "United Home Life Insurance Company", "Unitedhealthcare Life Insurance Company", "Careplus Health Plans, Inc.", "Infinity Auto Insurance Company", "Infinity Indemnity Insurance Company", "Life Insurance Company Of The Southwest", "National Life Insurance Company", "Progressive American Insurance Company", "Progressive Express Insurance Company", "Security National Insurance Company", "Molina Healthcare Of Ohio Inc", "Molina Healthcare Of Utah, Inc.", "Opticare Of Utah", "Selecthealth Inc", "Total Dental Administrators Of Utah, Inc", "First Penn-Pacific Life Insurance Company", "Genworth Life Insurance Company", "Nationwide Life Insurance Company", "Western National Life Insurance Company", "Liberty Bankers Life Insurance Company", "National Union Fire Insurance Company Of Pittsburgh Pa.", "National Union Fire Ins. Co. Of Pittsburgh Pa", "National Union Fire Insurance Company Of Pittsburgh Pennsylvania", "Garrison Property And Casualty Insurance Company", "United Services Automobile Association", "Usaa Casualty Insurance Company", "Usaa General Indemnity Company", "United Services Automobile Association, Usaa Reciprocal, Attorney-In-Fact", "Usaa General Indemnity Co", "Liberty National Life Ins Co", "American-Amicable Life Insurance Company Of Texas", "Americo Financial Life And Annuity Insurance Company", "Bluecross Blueshield Of Tennessee Inc.", "Liberty National Life Insurance Company", "Lincoln Heritage Life Insurance Company", "United American Insurance Company", "Washington National Insurance Company", "Columbian Life Insurance Company", "Molina Healthcare Of Wisconsin, Inc.", "Ameritas Life Ins Corp", "Thrivent Financial For Lutherans", "Ameritas Life Insurance Corporation", "Ameritas Life Insurance Corp.", "Freedom Life Insurance Company Of America", "National Foundation Life Insurance Company", "Unitedhealthcare Of Kentucky, Ltd.", "Unitedhealthcare Of Mississippi, Inc.", "Sierra Health And Life Insurance Company", "Ghi Hmo Select Inc", "Group Health Inc", "Health Ins Plan Of Greater New York", "Hip Ins Co Of New York", "Unitedhealthcare Ins Co Of Oh", "Unitedhealthcare Of Texas, Inc.", "Unimerica Insurance Company", "American Financial Security Life Insurance Company", "Freedom Life Ins Co Of America", "Starr Indemnity & Liability Company", "Wesco Ins Company", "Wesco Insurance Company", "Combined Ins Co Of America", "Wesco Insurance Co", "American Equity Investment Life Insurance Company", "Guarantee Trust Life Insurance Company", "Humana Marketpoint Inc -000", "Integrity Life Insurance Company", "Jackson National Life Insurance Co", "John Hancock Life Insurance Company (U.S.A.)", "Lincoln National Life Insurance Co (The)", "Manhattanlife Assurance Company Of America", "American Financial Security Life Insurance Co.", "American Dental Plan Of North Carolina, Inc.", "Cariten Insurance Company", "Caresource Kentucky Co.", "Caresource", "Allstate County Mutual Insurance Company", "Allstate Fire And Casualty Insurance Company", "Allstate Indemnity Company", "Allstate Insurance Company", "Allstate Property And Casualty Insurance Company", "Allstate Texas Lloyd'S", "Direct General Insurance Company", "Direct General Life Insurance Company", "First Acceptance Insurance Company, Inc.", "Old American County Mutual Fire Insurance Company", "Katch Ins Solutions Llc -000", "Madison National Life Insurance Company, Inc.", "Standard Security Life Ins Co Of Ny", "Molina Healthcare Of Michigan, Inc.", "Standard Security Life Insurance Company Of New York", "Katch Insurance Solutions Llc", "Molina Healthcare Of Washington Inc", "Accordia Life And Annuity Company", "Arches Mutual Insurance Company Dba Arches Health Plan", "Connecticut General Life Ins Co", "Wellcare Prescription Insurance Inc.", "Alliance Health And Life Insurance Company", "Health Alliance Plan Of Michigan", "American General Life Insurance Company", "Amerihealth Hmo, Inc.", "Independence American Insurance Company", "Madison National Life Insurance Company Inc", "Mega Life And Health Insurance Company", "Standard Security Life Insurance Company New York", "Mega Life And Health Insurance Company, The", "Independence Hospital Indemnity Plan, Inc.", "Keystone Health Plan East, Inc.", "Qcc Insurance Company", "Usable Life", "Independence American Insurance Company (Aic)", "Madison National Life Insurance Company, Inc", "Mega Life & Health Insurance Company, The", "Senior Life Insurance Company", "Sterling Investors Life Insurance Company", "Blue Cross Blue Shield Of Wyoming", "Wellmark Health Plan Of Iowa, Inc.", "Wellmark, Inc", "Extend Insurance Services Llc", "Bristol West Insurance Company", "Farmers Insurance Exchange", "Fire Insurance Exchange", "Foremost Insurance Company", "Mid-Century Insurance Company", "Truck Insurance Exchange", "Western Surety Company", "Combined Life Ins Co Of New York", "National Guardian Life Insurance Company", "Security National Life Insurance Company", "Independent Mutual Fire Insurance Company", "Progressive Casualty Insurance Company", "Progressive Hawaii Insurance Corporation", "Cmfg Life Insurance Company", "Cmfg Life Ins Co", "Colonial Life And Accident Insurance Company", "Settlers Life Insurance Company", "Cigna Healthcare Of Texas, Inc.", "North America Life Insurance Company", "Texas Service Life Insurance Company", "Ia American Life Insurance Company", "Royal Neighbors Of America", "Anthem Health Plans, Inc", "Connecticut General Life Ins", "Connecticut General Life Insurance Co", "Pyramid Life Insurance Company", "United States Pharmaceutical Group Llc -000", "United States Pharmaceutical Group Llc", "Berkshire Life Insurance Company Of America", "Guardian Insurance & Annuity Company, Inc.", "Guardian Life Insurance Company Of America", "John Hancock Life Insurance Company U.S.A.", "Neighborhood Health Partnership, Inc.", "United States Life Insurance Company In The City Of New York", "Cmfg  Life  Insurance Company", "5 Star Life Insurance Company", "Colorado Bankers Life Insurance Company", "Philadelphia American Life Insurance Company", "American National Life Insurance Company Of Texas", "Cica Life Insurance Company Of America", "Southwest Service Life Insurance Company", "United Investors Life Insurance Company", "Great American Life Insurance Company", "Hsa Health Insurance Company", "North American Company For Life & Health Insurance", "Pacific Life Insurance Company", "Voya Insurance And Annuity Company", "John Alden Life Insurance Company", "Unitedhealthcare Of Florida, Inc.", "American Memorial Life Insurance Company", "Phl Variable Insurance Company", "S.Usa Life Insurance Company, Inc.", "Bankers Life And Casualty Company", "Accc Insurance Company", "Wellcare Health Insurance Of Kentucky, Inc.", "Silver Script Insurance Company", "Ehealthinsurance Services, Inc.", "Wellcare Health Insurance Of Arizona, Inc.", "Chesapeake Life Insurance Company (The)", "Ehealthinsurance Services Inc -000", "Good Health Hmo, Inc. D/B/A Blue-Care", "Guardian Insurance & Annuity Co, Inc.", "Guardian Life Insurance Co Of America (The)", "North River Insurance Company (The)", "Sagicor Life Insurance Company", "Security Life Insurance Company Of America", "Standard Life & Accident Insurance Co", "Sun Life Assurance Company Of Canada", "United States Fire Insurance Company", "United Teacher Associates Insurance Co", "Vision Service Plan Insurance Company", "Fallon Community Health Plan, Inc.", "Medica Health Plan", "Medica Insurance Company", "Medica Health Plans", "Medco Containment Life Insurance  Company", "Unitedhealthcare Of New England Inc", "Medco Containment Life Ins Co", "Wellmark Of Sd Inc  (Dba: Blue Cross/Blue Shield Of Sd)", "Allstate Life Insurance Company", "Allstate Motor Club, Inc", "American Commerce Insurance Company", "American Heritage Life Insurance Company", "Lincoln Benefit Life Company", "American Medical And Life Insurance Company", "Humana Marketpoint Inc", "American General Life Ins Company", "Brighthouse Life Insurance Company", "Lincoln National Life Insurance Company (The)", "Sentinel Security Life Insurance Company", "United Healthcare Of The Mid- Atlantic, Inc.", "Delta Dental Insurance Company", "Oxford Life Insurance Company", "Trustmark Insurance Company", "Independent Order Of Foresters", "Sentinel Security Life Insurance Co", "Manhattan Life Insurance Company", "John Hancock Life Insurance Company (Usa)", "Gerber Life Ins Co", "Metropolitan Life Ins Co", "Manhattan Life Insurance Company (The)", "Manhattan Life Ins Co", "Sentinel Security Life Ins Co", "Lincoln National Life Insurance Company, The", "Independent Order Of Foresters The", "Lincoln National Life Insurance Company The", "Pre-Paid Legal Casualty, Inc.", "Family Heritage Life Ins Co Of America", "Healthmarkets Insurance Agency Inc -000", "Mid-West National Life Insurance Co Of Tennessee", "Standard Insurance Company", "Healthmarkets Insurance Agency, Inc.", "Equitrust Life Insurance Company", "Guardian Insurance & Annuity Company, Inc. (The)", "Axa Equitable Life Insurance Company", "Continental Casualty Company", "Genworth Life And Annuity Insurance Company", "Guardian Insurance & Annuity Company, Inc., The", "Guardian Life Insurance Company Of America, The", "Lafayette Life Insurance Company, The", "Massachusetts Mutual Life Insurance Company", "Penn Insurance & Annuity Company", "Penn Mutual Life Insurance Company", "Prudential Annuities Life Assurance Corporation", "Security Benefit Life Insurance Company", "Zurich American Life Insurance Company", "Great Western Insurance Company", "Wellcare Of Florida, Inc.", "Amerihealth Insurance Company Of New Jersey", "Oxford Health Plans (Ct), Inc.", "Sierra Health And Life Insurance Company, Inc", "Vision Services Plan Inc., Oklahoma", "Fidelity Security Life Insurance Company", "Humana Marketpoint, Inc.", "Mutual Of Omaha Ins Co", "Madison National Life Insurance Company Inc.", "Standard Security Life Insurance Company Of Ny", "Nevada Pacific Dental", "National Pacific Dental, Inc.", "Axis Insurance Company", "Lifeshield National Insurance Company", "Golden Rule Ins Company", "Standard Security Life Insurance Co. Of New York", "Golden Rule Ins Co", "Guarantee Trust Life Ins Co", "American Family Life Assurance Company Of Columbus (Aflac)", "United American Ins Co", "Nationwide Life And Annuity Insurance Company", "Symetra Life Insurance Company", "Federal Life Insurance Company", "Dairyland Insurance Company", "Esurance Property And Casualty Insurance Company", "Infinity Safeguard Insurance Company", "Infinity Select Insurance Company", "Metropolitan Property & Casualty Ins Co", "Peak Property And Casualty Insurance Corporation", "Progressive Specialty Ins Company", "Safeco Insurance Company Of America", "Safeco Insurance Company Of Illinois", "Titan Indemnity Co", "Usaa Life Ins Company", "Victoria Fire & Casualty Co", "Victoria Select Insurance Co", "Dairyland Ins Co", "Esurance Property & Casualty Insurance Company", "Metropolitan Property And Casualty Insurance Company", "Progressive Northwestern Insurance Company", "Safeco Ins Co Of Illinois", "United Financial Casualty Company", "Usaa Life Insurance Company", "Victoria Fire & Casualty Company", "Viking Insurance Company Of Wisconsin", "Infinity Insurance Company", "Metropolitan Direct Property And Casualty Insurance Company", "Foremost Insurance Company Grand Rapids, Michigan", "General Insurance Company Of America", "Victoria Fire And Casualty Company", "21st Century Centennial Insurance Company", "Progressive Northern Insurance Company", "Titan Indemnity Company", "Mercury Indemnity Company Of America", "American Economy Insurance Company", "American States Insurance Company", "American States Insurance Company Of Texas.", "American States Preferred Insurance Company", "First National Insurance Company Of America", "Grange Indemnity Insurance Company", "Grange Mutual Casualty Company", "Grange Property And Casualty Insurance Company", "Infinity Casualty Insurance Company", "Mercury Indemnity Company Of Georgia", "Mercury Insurance Company Of Georgia", "Metropolitan Casualty Insurance Company", "Metropolitan General Insurance Company", "Patriot General Insurance Company", "Progressive Mountain Insurance Company", "Safeco Insurance Company Of Indiana", "Safeco National Insurance Company", "Trustgard Insurance Company", "Victoria Select Insurance Company", "Victoria Specialty Insurance Company", "Usaa Financial Planning Services Insurance Agency, Inc.", "Integrity Mutual Insurance Company", "Integrity Property & Casualty Insurance Company", "Victoria Automobile Insurance Company", "Aig Property Casualty Company", "Aiu Insurance Company", "Allied Insurance Company Of America", "Allied Property And Casualty Insurance Company", "Amco Insurance Company", "American Bankers Insurance Company Of Florida", "American Fire And Casualty Company", "American Hallmark Insurance Company Of Texas", "American Zurich Insurance Company", "Automobile Insurance Company Of Hartford, Connecticut (The)", "Depositors Insurance Company", "Foremost Signature Insurance Company", "Hartford Accident And Indemnity Company", "Hawkeye-Security Insurance Company", "Insurance Answer Center Llc -000", "Insurance Company Of The State Of Pennsylvania (The)", "Midwestern Indemnity Company (The)", "Nationwide Affinity Insurance Company Of America", "Nationwide Agribusiness Insurance Company", "Nationwide Mutual Insurance Company", "Netherlands Insurance Company (The)", "Ohio Casualty Insurance Company (The)", "Ohio Security Insurance Company", "Peerless Indemnity Insurance Company", "Peerless Insurance Company", "Phoenix Insurance Company (The)", "Qbe Insurance Corporation", "Sentinel Insurance Company, Ltd.", "Standard Fire Insurance Company (The)", "Stillwater Insurance Company", "Travco Insurance Company", "Travelers Home And Marine Insurance Company (The)", "Travelers Indemnity Company Of America (The)", "Travelers Property Casualty Insurance Company", "Twin City Fire Insurance Company", "Usaa Financial Planning Services Insurance Agency Inc-000", "West American Insurance Company", "Esurance Insurance Company", "Grange Property & Casualty Insurance Company", "American Strategic Insurance Corp.", "Everest National Insurance Company", "Mercury National Insurance Company", "Progressive Michigan Insurance Company", "American Security Insurance Company", "Integrity Property And Casualty Insurance Company", "Progressive Preferred Insurance Company", "Coast National Insurance Company", "Progressive Gulf Insurance Company", "Economy Fire And Casualty Insurance Company", "Economy Preferred Insurance Company", "Progressive Southeastern Insurance Company", "United Services Automobile Assoc.", "Metropolitan Property & Casualty Insurance Company", "Esurance Insurance Company Of New Jersey", "Metropolitan Group Property And Casualty Insurance Company", "Safeway Insurance Company", "Sentry Insurance A Mutual Company", "Garrison Property And Casualty", "Mercury Casualty Company", "American States Ins Co", "Esurance Ins Co", "Esurance Property And Casualty Ins Co", "Metropolitan Casualty Ins Co", "Metropolitan Property And Casualty Ins Co", "Progressive Casualty Ins Co", "Safeco Ins Co Of America", "Safeco Ins Co Of Indiana", "Safeco National Ins Co", "Usaa Life Ins Co Of New York", "Progressive Specialty Insurance Company", "American Mercury Insurance Company", "American Strategic Insurance Corporation", "First National Ins Co Of America", "Garrison Property And Casualty Insurance Co.", "General Ins Co Of America", "Grange Mutual Casualty Co", "Peak Property And Casualty Ins Corp", "Usaa Life Ins Co", "Esurance Property And Casualty Insurance Co", "Progressive Northern Ins Co", "United Financial Casualty Co", "American Mercury Lloyd'S Insurance Company", "Colonial County Mutual Insurance Company", "Dairyland County Mutual Insurance Company Of Texas", "Foremost County Mutual Insurance Company", "Foremost Insurance Company  Grand Rapids, Michigan", "Foremost Lloyds Of Texas", "Home State County Mutual Insurance Company", "Infinity County Mutual Insurance Company", "Liberty County Mutual Insurance Company", "Mercury County Mutual Insurance Company", "Metropolitan Lloyds Insurance Company Of Texas", "Physicians Life Insurance Company", "Physicians Mutual Insurance Company", "Progressive County Mutual Insurance Company", "Ranchers And Farmers Mutual Insurance Company", "Safeco Lloyds Insurance Company", "Usaa Conversion Insurance Company", "Usaa County Mutual Insurance Company", "Metropolitan Property & Casualty Insurance Co", "Insurance Company Of Illinois", "Insurance Answer Center Llc", "Middlesex Insurance Company", "Usaa Financial Planning Services Insurance Agency", "Artisan And Truckers Casualty Company", "Progressive Classic Insurance Company", "Allstate Vehicle And Property Insurance Company", "Farmers Texas County Mutual Insurance Company", "Mid-Century Insurance Company Of Texas", "Ohio National Life Insurance Company", "Texas Farmers Insurance Company", "Molina Healthcare Of New Mexico, Inc.", "Gateway Health Plan Of Ohio, Inc.", "Gateway Health Plan Of Ohio Inc", "Gateway Health Plan, Inc.", "Blue Shield Of California Life & Health Insurance Company", "Aultcare Health Insuring Corporation", "Aultcare Insurance Company", "Health Plan Of West Virginia, Inc. The", "Healthspan Integrated Care", "Mount Carmel Health Insurance Company", "Mount Carmel Health Plan Inc", "Thp Insurance Company Inc", "Capital Advantage Insurance Company", "Capital Blue Cross", "Highmark Benefits Group Inc.", "Highmark Choice Company", "Highmark Coverage Advantage Inc.", "Highmark Inc.", "Highmark Select Resources Inc.", "Highmark Senior Health Company", "Hm Health Insurance Company", "Upmc Health Network, Inc.", "Upmc Health Plan, Inc.", "American General Life Insurance Company Of Delaware", "Annuity Investors Life Insurance Company", "Central States Indemnity Company Of Omaha", "Ucare Health, Inc.", "The Health Plan Of West Virginia, Inc.", "Thp Insurance Company", "American Modern Select Insurance Company", "American National General Insurance Company", "American National Property And Casualty Company", "Foremost Insurance Company Grand Rapids Michigan", "Foremost Property And Casualty Insurance Company", "Geovera Insurance Company", "Northeast Agencies Inc", "Standard Life And Accident Insurance Company", "Occidental Life Insurance Company Of N Carolina", "Pioneer American Insurance Company", "New York Life Insurance & Annuity Corporation", "Nylife Insurance Company Of Arizona", "American Progressive Life And Health Ins Co Of New York", "Excellus Health Plan Inc", "Healthnow New York Inc", "Mvp Health Plan Inc", "Clear Link Ins Agency Llc -000", "First Liberty Insurance Corporation (The)", "Liberty Insurance Corporation", "Liberty Mutual Insurance Company", "Lm Insurance Corporation", "Clear Link Insurance Agency, Llc", "Lifewise Health Plan Of Washington", "Premera Blue Cross", "Allianz Life Ins Company Of North America", "American Traveler Motor Club Inc", "American Traveler Motor Club, Llc.", "Peak Property And Casualty Insurance Corp.", "American Traveler Motor Club, Inc. (The)", "Futurity First Ins Group Inc -000", "Liberty Mutual Fire Insurance Company", "Lm General Insurance Company", "Permanent General Assurance Corporation", "State Life Insurance Company", "United Security Assurance Company Of Pennsylvania", "American Traveler Motor Club, Llc/The", "American Traveler Motor Club, Llc (The)", "Bristol West Casualty Insurance Company", "Forethought Life Insurance Company", "Security Life Of Denver Insurance Company", "General Automobile Insurance Company, Inc., The", "Permanent General Assurance Corporation Of Ohio", "Americo Financial Life & Annuity Insurance Company", "Bankers Fidelity Life Insurance Company", "Fidelity & Guaranty Life Insurance Company", "National States Insurance Company", "Order Of United Commercial Travelers Of America", "Standard Life & Accident Insurance Company", "Futurity First Insurance Group Inc", "Wellcare  Prescription Insurance, Inc.", "American Progressive Life And Health Insurance Company Of New York", "Unicare Life And Health Insurance Company", "Bravo Health Texas, Inc.", "Memorial Hermann Health Insurance Company", "Pyramid Life Insurance Company, The", "Texas Healthspring, Llc", "Hartford Life & Annuity Insurance Company", "Pacificare Life & Health Insurance Company", "Standard Life & Casualty Insurance Company", "Continental American Insurance Company", "Everest Reinsurance Company", "National Western Life Ins Company", "Medstar Family Choice", "Provident Life & Accident Company", "Reliastar Life Insurance Co", "Symphonix Health Insurance Inc.", "Oxford Health Plan (Nj) Inc", "Vantis Life Insurance Company", "Individual Assurance Company Life Health & Accident", "Sierra Health And Life Insurance Company Inc", "Reliastar Life Ins Co Of New York", "Trustmark Ins Co", "Trustmark Life Ins Co Of New York", "Premier Health Insuring Corporation", "National Western Life Insurance Company", "Continental American Insurance Co", "United Of Omaha Life Ins Co", "Individual Assurance Company Life, Health & Accident", "Mutual Of Omaha Ins Company", "Reliastar Life Ins Co", "Midland National Life Insurance Company", "Mamsi Life And Health Insurance Company", "Western Reserve Life Assurance Co Of Ohio", "Avmed, Inc.", "Safeguard Health Plans, Inc.", "Allstate Northbrook Indemnity Company", "Allstate Property & Casualty Insurance Company", "Allstate New Jersey Insurance Company", "Allstate New Jersey Property And Casualty Insurance Company", "Allstate Indemnity Co", "Allstate Property And Casualty Ins Co", "Allstate Vehicle & Property Insurance Company", "Investors Insurance Corporation", "Nationwide General Insurance Company", "Nationwide Lloyds", "Nationwide Mutual Fire Insurance Company", "Nationwide Property And Casualty Insurance Company", "State Farm County Mutual Insurance Company Of Texas", "State Farm Fire And Casualty Company", "State Farm General Insurance Company", "State Farm Life Insurance Company", "State Farm Lloyds", "State Farm Mutual Automobile Insurance Company", "Western Reserve Life Assurance Co. Of Ohio", "Allstate Fire & Casualty Insurance Company", "Conseco Insurance Company", "Independent Order Of Foresters, The", "State Mutual Insurance Company", "Ucare Minnesota", "Paramount Care Inc", "Paramount Insurance Company", "Metlife Investors Usa Insurance Company", "Highmark Senior Solutions Company", "Highmark West Virginia Inc.", "Tpusa Inc", "Carefirst Bluechoice, Inc.", "First Care, Inc.", "Group Hospitalization And Medical Services., Inc.", "Hmo Colorado Inc  D/B/A Hmo Nevada", "Rocky Mountain Hospital And Medical Service Inc", "Ghs Health Maintenance Organization, Inc.", "Universal Health Care Insurance Company, Inc.", "Community Health Alliance Mutual Insurance Company", "Equitable Life And Casualty Insurance Company", "Independent Order Of Foresters (Us Branch)", "Pyramid Life Insurance Company (The)", "Express Scripts Insurance Company", "Blue Cross And Blue Shield Of S C", "Pennsylvania Life Ins Co", "Sterling Life Ins Co", "American Family Life Insurance Company", "Continental Western Insurance Company", "Farm Bureau Life Insurance Company", "Farm Bureau Property & Casualty  Insurance Company", "Federated Life Insurance Company", "Federated Mutual Insurance Company", "Federated Service Insurance Company", "Firemen'S Insurance Company Of Washington Dc", "Union Insurance Company", "Western Agricultural Insurance Company", "Mutual Trust Life Insurance Company, A Pan-American Life Insurance Group", "Mutual Trust Life Ins Co, A Pan-American Life Ins Group Stock Co", "Lafayette Life Insurance Company", "Mutual Trust Life Insurance Company, A Pan-American Life Insurance Group Stock Company", "C. M. Life Insurance Company", "Massachusetts Mutual Life Ins Co", "Security Mutual Life Ins Co Of New York", "C.M. Life Insurance Company", "Lafayette Life Insurance Company (The)", "Athene Annuity & Life Assurance Company Of New York", "North Carolina Mutual Life Insurance Company", "Automobile Insurance Company Of Hartford, Connecticut, The", "First Liberty Insurance Corporation, The", "Guideone America Insurance Company", "Guideone Elite Insurance Company", "Guideone Mutual Insurance Company", "Guideone Specialty Mutual Insurance Company", "National Security Fire And Casualty Company", "Phoenix Insurance Company, The", "Standard Fire Insurance Company, The", "Travelers Home And Marine Insurance Company, The", "21st Century Premier Insurance Company", "Aegis Security Insurance Company", "Aig Assurance Company", "American Family Home Insurance Company", "American Modern Home Insurance Company", "American Pioneer Life Insurance Company", "American Southern Home Insurance Company", "Anchor Specialty Insurance Company", "Assurance Company Of America", "Bond Safeguard Insurance Company", "Charter Oak Fire Insurance Company, The", "Consolidated Insurance Company", "Crestpoint Health Insurance Company", "Delta Dental Of Tennessee", "Falls Lake National Insurance Company", "Farmington Casualty Company", "First Liberty Insurance Corporation", "General Automobile Insurance Company Inc.", "Generali (Us Branch)", "Illinois Mutual Life Insurance Company", "Illinois National Insurance Company", "Indiana Insurance Company", "Maryland Casualty Company", "Mountain Laurel Assurance Company", "National Lloyds Insurance Company", "National Security Insurance Company", "Netherlands Insurance Company, The", "Northern Insurance Company Of New York", "Ohio Casualty Insurance Company, The", "Pan-American Life Insurance Company", "Penn Treaty Network America Insurance Company", "Principal Life Insurance Company", "Progressive Advanced Insurance Company", "Seneca Insurance Company, Inc.", "Star Casualty Insurance Company", "Starmount Life Insurance Company", "Travelers Casualty And Surety Company", "Travelers Casualty Insurance Company Of America", "Travelers Commercial Casualty Company", "Travelers Commercial Insurance Company", "Travelers Indemnity Company Of America, The", "Travelers Indemnity Company Of Connecticut, The", "Travelers Indemnity Company, The", "Travelers Personal Security Insurance Company", "Travelers Property Casualty Company Of America", "Windhaven National Insurance Company", "Vision Service Plan", "Loyal American Life Ins Co", "Pioneer Security Life Insurance Company", "Baltimore Life Insurance Company, The", "United National Life Insurance Company Of America", "Sierra Health & Life Ins Company, Inc.", "Cincinnati Life Ins Co", "Security National Life Ins Company", "Markel Ins Co", "Cincinnati Life Insurance Company", "Family Benefit Life Insurance Company", "Grange Life Insurance Company", "Horace Mann Life Insurance Company", "Standard Life And Casualty Insurance Company", "Alpha Property & Casualty Insurance Company", "Savings Bank Mutual Life Insurance Company Of Massachusetts, The", "Stillwater Property And Casualty Insurance Company", "University Of Utah Health Plans", "Life Insurance Company Of Alabama", "Savings Bank Mutual Life Insurance Company Of Massachusetts (The)", "Union Central Life Insurance Company", "Woodmen Of The World Life Insurance Society", "Cm Life Insurance Company", "Massachusetts Mutual Life Insurance Co", "C.M. Life Ins Co", "North American Company For Life And Health Ins", "United World Life Ins Co", "Caremore Health Plan Of Nevada", "First Acceptance Insurance Company Of Tennessee, Inc.", "American United Life Insurance Company", "Assured Life Association", "Conseco Health Insurance Company", "Jackson National Life Insurance Company", "Pioneer Mutual Life Insurance Company", "Regence Blue Cross Blue Shield Of Utah", "State Life Insurance Company, The", "Western Reserve Life Assurance Company Of Ohio", "American Republic Corp Insurance Company", "American Republic Insurance Company", "Baltimore Life Insurance Company", "Bankers Fidelity Assurance Company", "Cigna Healthcare Of Tennessee, Inc.", "Kansas City Life Insurance Company", "Mid-West National Life Insurance Company Of Tennessee", "Nationwide Assurance Company", "Occidental Life Insurance Company Of North Carolina", "Texas Life Insurance Company", "New York Life Insurance & Annuity Corp", "Smart Insurance Company", "Puritan Life Insurance Company Of America", "Chesapeake Life Insurance Company/ The", "Nationwide Life & Annuity Insurance Company", "Unity Financial Life Insurance Company", "Direct Insurance Company", "Direct National Insurance Company", "Nation Motor Club, Llc.", "Direct General Insurance Company Of Mississippi", "Allmerica Financial Alliance Insurance Company", "Hanover American Insurance Company, The", "Hanover Insurance Company, The", "Massachusetts Bay Insurance Company", "Ambetter Of Magnolia Inc.", "Cincinnati Casualty Company, The", "Cincinnati Indemnity Company, The", "Cincinnati Insurance Company, The", "Foremost Property & Casualty Insurance Company", "Old Republic Insurance Company", "Old Republic Surety Company", "Chesapeake Life Ins Company", "Chesapeake Life Insurance Company The", "Northwestern Mutual Life Insurance Company", "Lincoln Heritage Life Insurance Company: Active", "World Insurance Company", "National General Insurance Company", "Unigard Insurance Company", "Asi Select Insurance Corp.", "Balboa Insurance Company", "Excelsior Insurance Company", "Montgomery Mutual Insurance Company", "Ohio Casualty Insurance Company", "The Automobile Insurance Company Of Hartford, Connecticut", "The Phoenix Insurance Company", "The Standard Fire Insurance Company", "The Travelers Home And Marine Insurance Company", "The Travelers Indemnity Company", "The Travelers Indemnity Company Of America", "Employers Insurance Company Of Wausau", "Empire Fire And Marine Insurance Company", "General Casualty Insurance Company", "Praetorian Insurance Company", "Travelers Indemnity Company (The)", "Travelers Indemnity Company Of Connecticut (The)", "Colorado Casualty Insurance Company", "Empire Fire & Marine Insurance Company", "Meritplan Insurance Company", "Balboa Ins Co", "General Casualty Co Of Wisconsin", "Kemper Independence Ins Co", "Qbe Ins Corporation", "Unitrin Auto And Home Ins Co", "Unitrin Preferred Ins Co", "American States Insurance Company Of Texas", "General Casualty Company Of Wisconsin", "Mid-American Fire & Casualty Company", "Midwestern Indemnity Company, The", "Charter Oak Fire Insurance Company (The)", "Unitrin Auto And Home Insurance Company", "Automobile Ins Co Of Hartford Conn", "Meritplan Ins Co", "National General Ins Co", "Phoenix Ins Co", "Southern Pilot Insurance Company", "Standard Fire Ins Co", "Travelers Casualty Company Of Connecticut", "Travelers Indemnity Co", "America First Insurance Company", "America First Lloyd'S Insurance Company", "Aventus Insurance Company", "Commercial Alliance Insurance Company", "Consumers County Mutual Insurance Company", "Kemper Independence Insurance Company", "Mapfre Tepeyac, S.A.", "National Specialty Insurance Company", "Texas Select Lloyds Insurance Company", "Trinity Universal Insurance Company", "Unitrin Preferred Insurance Company", "Unitrin Safeguard Insurance Company", "West Coast Life Insurance Company", "Automobile Insurance Company Of Hartford Connecticut The", "Charter Oak Fire Insurance Company The", "Netherlands Insurance Company The", "Newport Insurance Company", "Ohio Casualty Insurance Company The", "Phoenix Insurance Company The", "Southern Fire & Casualty Company", "Standard Fire Insurance Company The", "Travelers Indemnity Company Of America The", "Travelers Indemnity Company The", "Summit Global Partners Of Texas Inc", "Usi Insurance Services Llc", "Auto-Owners Insurance Company", "Auto-Owners Life Insurance Company", "Owners Insurance Company", "Liberty Life Assurance Company Of Boston", "Allstate Assurance Company", "Allstate Ins Co", "American Modern Lloyd'S Insurance Company", "First Guaranty Insurance Company", "Dearborn National Life Insurance Company"]
