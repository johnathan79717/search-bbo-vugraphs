class MainController < ApplicationController
  def index
    if params[:seqence]
      @boards = Board.find_auction params[:sequence]
    else
      @boards = []
    end
  end
end