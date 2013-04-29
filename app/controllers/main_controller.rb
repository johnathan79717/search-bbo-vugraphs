class MainController < ApplicationController
  def index
    @sequence = params[:sequence]
    if params[:sequence]
      @boards = Board.find_auction params[:sequence].upcase
    else
      @boards = []
    end
  end
end