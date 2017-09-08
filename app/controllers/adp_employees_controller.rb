class AdpEmployeesController < ApplicationController

  def index
    @adps = AdpEmployee.all
  end
end
