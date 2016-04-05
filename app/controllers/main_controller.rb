class MainController < ApplicationController
  def download
    render text: 'Start downloading'
    Vugraph.download(1..params[:id].to_i)
  end

  def last
    render text: Vugraph.last.id
  end

  def index
    @sequence = params[:sequence]
    @link_prefix = 'http://www.bridgebase.com/tools/handviewer.html?linurl=http://www.bridgebase.com/tools/vugraph_linfetch.php?id='
    if !params[:sequence]
      @boards = []
      return
    end

    @boards = Rails.cache.fetch("#{params[:player]}/#{params[:sequence]}", expires_in: 1.minute) do
      boards =
        if params[:player].empty?
          Board.all
        else
          @player = Player.find_by_name(params[:player].upcase)
          @player ? @player.boards : []
        end

      boards.find_all do |board|
        board.auction.match(/\A(- ){,3}#{params[:sequence]}/)
      end
    end

    @boards = @boards.paginate(page: params[:page])
  end
end
