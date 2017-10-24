class SalesmenController < ApplicationController
  before_action :set_salesman, only: [:show, :edit, :update, :destroy]
   skip_before_filter :verify_authenticity_token

  # GET /salesmen
  # GET /salesmen.json
  def index
    @filterrific = initialize_filterrific(
      Salesman,
      params[:filterrific],
      :select_options => {
        sorted_by: Salesman.options_for_sorted_by
      }
    ) or return
    @salesmen = @filterrific.find.page(params[:page])

    respond_to do |format|
      format.html
      format.js
    end
    # TODO @salesman.includes(:states).includes(:licenses)
    # Based off loation licensing stragety
    # Get sample data from adp
  end

  # GET /salesmen/1
  # GET /salesmen/1.json
  def show
    @salesman = Salesman.find(params[:id])
    @salesman_first = @salesman.first_name.present? ? @salesman.first_name : @salesman.given_name
    @salesman_last = @salesman.last_name.present? ? @salesman.last_name : @salesman.family_name
    @licensed_states = @salesman.states.all.compact
    @active_licenses = @licensed_states.map { |st| st.licenses.where(active: 'Y')}
    @active_licenses_states_names = @active_licenses.count > 0 ? @active_licenses.flatten.map {|l| l.state.name } : @active_licenses = []
    @appointed_states = @salesman.states.includes(:appointments).map{|s| s if s.appointments.count > 0 }.compact
    @non_appointed_states = @salesman.states.includes(:appointments).map{|s| s if s.appointments.count < 1 }.compact
    @expired_states = @salesman.states.includes(:licenses).where('date_expire_license < ?', Time.now).references(:licenses)
    @expired_states_names = @expired_states.map(&:name)
    @needed_states = states_needed_per_site(@salesman)
    # @check_or_naw = get_check_mark_for_agent(@salesman, @appointed_states.map(&:name))
    @all_salesman_states = @salesman.states.all.map(&:name)
    @non_licensed_states = all_states_names - @all_salesman_states
    @licensed_states_names = @licensed_states.map(&:name)
    @appointed_states_names = @appointed_states.map(&:name)
    @can_sell_states = [@appointed_states_names].flatten.uniq.compact
    @check_or_naw = @needed_states - @can_sell_states
    @non_sellable_states_names = [@expired_states.compact.map(&:name), @non_appointed_states.compact.map(&:name)]
    @salesman.agent_site.present? ? @jit_states = sites_with_just_in_time_states : @jit_states = []
    @salesman.agent_site.present? ? @states_needed = states_needed_per_site(@salesman) : @states_needed = all_states_names
    @salesman.agent_site.present? ? @states_needed = states_needed_per_site(@salesman) : @states_needed = all_states_names
    @all_states_names = all_states_names
  end

  # GET /salesmen/new
  def new
    @salesman = Salesman.new
  end

  # GET /salesmen/1/edit
  def edit
  end

  def adp_employees
    @adps = AdpEmployee.all
  end

  def update_salesman_report
    salesman = Salesman.find(params[:id])
    salesman.update_states_licensing_info
    redirect_to salesman_path(salesman)
  end

  def update_npn_and_licensing_info
    salesman = Salesman.find(params[:id]).update_npn_and_get_data(params[:salesman][:npn])
    redirect_to salesman_path(salesman)
  end

  def find_agent

  end

  def filter_agents
  end

  def agent_search

  end

  def xlsheet_data
    Salesman.update_npns_from_spread_sheet
    Salesman.get_data_from_sandbox_reporting
    redirect_to root_path
  end

  def agent
    agent = Salesman.find_by(npn: params[:npn])
    if agent.present?
      redirect_to salesman_path(agent)
    else
      redirect_to find_agent_path, notice: "Agent with that NPN doesn't exist."
    end
  end

  # POST /salesmen
  # POST /salesmen.json
  def create
    @salesman = Salesman.new(salesman_params)

    respond_to do |format|
      if @salesman.save
       	@salesman.update_npn_and_get_data(@salesman.npn) if @salesman.npn.present?
        format.html { redirect_to @salesman, notice: 'Agent was successfully created.' }
        format.json { render :show, status: :created, location: @salesman }
      else
        format.html { render :new }
        format.json { render json: @salesman.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /salesmen/1
  # PATCH/PUT /salesmen/1.json
  def update
    respond_to do |format|
      if @salesman.update(salesman_params)
        format.html { redirect_to @salesman, notice: 'Agent was successfully updated.' }
        format.json { render :show, status: :ok, location: @salesman }
      else
        format.html { render :edit }
        format.json { render json: @salesman.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /salesmen/1
  # DELETE /salesmen/1.json
  def destroy
    @salesman.destroy
    respond_to do |format|
      format.html { redirect_to salesmen_url, notice: 'Agent was successfully destroyed.' }
      format.json { head :no_content }
    end
  end


    # Use callbacks to share common setup or constraints between actions.
  def set_salesman
    @salesman = Salesman.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def salesman_params
    params.require(:salesman).permit(:npn, :first_name, :last_name)
  end

  def get_check_mark_for_agent(agent, states)
    if agent.home_work_location_city.present? || agent.agent_site.present?
        states_needed_per_site(agent) - states
    else
        all_states_names - states
    end
  end

  def states_needed_per_site(salesman)
    if salesman.client == "Anthem"
      anthem_states
    else
      case [salesman.agent_site, salesman.home_work_location_city].compact.uniq
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
    "AL AZ CO IL IN KY LA MT OH OR PA PR RI UT VT WA WI AK AR CA CT DE DC FL GA HI ID IA KS ME MD MA MI MN MS MO NE NV NH NJ NM NY NC ND OK SC SD TN TX VA WV WY".split(" ")
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
    ["AK", "AR", "CA", "CT", "DE", "DC", "FL", "GA", "HI", "ID", "IA", "KS", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OK", "SC", "SD", "TN", "TX", "VA", "WV","WY"]
  end

  def sites_with_just_in_time_states
    jit_states
  end
end
