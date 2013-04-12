class MainController < ApplicationController
  def index
    if params[:sequence]
      @sequence = params[:sequence].split
  end
end