class MainController < ApplicationController
  def download
    render text: 'Start downloading'
    Vugraph.download(Vugraph.last.id-10..params[:id].to_i)
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

    @boards =
      if params[:player].empty?
        @boards = Board.all
      else
        @player = Player.find_by_name(params[:player].upcase)
        if @player
          @player.boards
        else
          []
        end
      end.find_all do |board|
        #board.auction =~ /\A(- ){,3}#{params[:sequence]}/
        board.auction.match(/\A(- ){,3}#{params[:sequence]}/)
      end
  end
end
