class StateDetailsController < ApplicationController
  before_action :set_state_detail, only: [:show, :edit, :update, :destroy]

  # GET /state_details
  # GET /state_details.json
  def index
    @state_details = StateDetail.all
  end

  # GET /state_details/1
  # GET /state_details/1.json
  def show
  end

  # GET /state_details/new
  def new
    @state_detail = StateDetail.new
  end

  # GET /state_details/1/edit
  def edit
  end

  # POST /state_details
  # POST /state_details.json
  def create
    @state_detail = StateDetail.new(state_detail_params)

    respond_to do |format|
      if @state_detail.save
        format.html { redirect_to @state_detail, notice: 'State detail was successfully created.' }
        format.json { render :show, status: :created, location: @state_detail }
      else
        format.html { render :new }
        format.json { render json: @state_detail.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /state_details/1
  # PATCH/PUT /state_details/1.json
  def update
    respond_to do |format|
      if @state_detail.update(state_detail_params)
        format.html { redirect_to @state_detail, notice: 'State detail was successfully updated.' }
        format.json { render :show, status: :ok, location: @state_detail }
      else
        format.html { render :edit }
        format.json { render json: @state_detail.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /state_details/1
  # DELETE /state_details/1.json
  def destroy
    @state_detail.destroy
    respond_to do |format|
      format.html { redirect_to state_details_url, notice: 'State detail was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_state_detail
      @state_detail = StateDetail.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def state_detail_params
      params.fetch(:state_detail, {})
    end
end
