class MainController < ApplicationController
  def index
    if params[:sequence]
      @boards = Board.find_auction params[:sequence].upcase
    else
      @boards = []
    end
  end
end