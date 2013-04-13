class MainController < ApplicationController
  def index
    @boards = Board.find_auction '1C'
  end
end