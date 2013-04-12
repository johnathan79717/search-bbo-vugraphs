class MainController < ApplicationController
  def index
    @sequence = (params[:sequence] || ['1C'])
    @results = Lin.find_board(@sequence)
  end
end