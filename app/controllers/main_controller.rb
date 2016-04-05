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

    query = 'auction LIKE ? OR auction LIKE ? OR auction LIKE ? OR auction LIKE ?'
    #sequences = [@sequence, '- ' + @sequence, '- ' * 2 + @sequence, '- ' * 3 + @sequence]
    sequences = (0..3).map do |x|
      '- ' * x + @sequence + '%'
    end
    p sequences
    @boards =
      if params[:player].empty?
        #@boards = Board.all
        Board.where(query, *sequences)
      else
        @player = Player.find_by_name(params[:player].upcase)
        if @player
          @player.boards.where(query, *sequences)
        else
          []
        end
      #end.find_all do |board|
        ##board.auction =~ /\A(- ){,3}#{params[:sequence]}/
        #board.auction.match(/\A(- ){,3}#{params[:sequence]}/)
      end
    
    @boards.each do |b|
      if b.hands.nil?
        p b
      end
    end
  end
end
