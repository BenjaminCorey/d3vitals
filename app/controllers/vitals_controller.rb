class VitalsController < ApplicationController
  respond_to :json, :html
  def index
    @vitals = Vital.all
    respond_with @vitals
  end

end
