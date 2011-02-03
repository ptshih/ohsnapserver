class CheckinController < ApplicationController
  before_filter do |controller|
    # This will set the @version variable
    controller.load_version(["v1","v2","v3"])
  end
  
  def index
  end
  
  def show
  end
end
