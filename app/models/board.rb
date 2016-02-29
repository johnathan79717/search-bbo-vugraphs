require 'net/http'

class ParseError < StandardError
  def initialize(msg)
    self.message = msg
  end
end

class Board < ActiveRecord::Base
  attr_accessible :number, :hands, :auction, :explanation, :comments, :seats
  belongs_to :vugraph
  has_many :players_boards, class_name: 'PlayersBoard'
  has_many :players, class_name: 'Player', through: :players_boards
  #has_and_belongs_to_many :players

  def parse_room_number players
    m = @string.match(/\Aqx\s*\|\s*(?<room>o|c)(?<number>\d+)\s*\|/)
    raise ParseError.new 'Bad room or number' if m.nil?

    if m['room'] == 'o'
      @players = players[0..3]
    else
      @players = players[4..7]
    end

    self.number = m['number']
  end

  def parse_hands
    m = @string.match(/\|\s*md\s*\|(?<hands>.*?)\|sv/)
    raise ParseError.new 'Bad hands' if m.nil?
    self.hands = m['hands']
  end
    
  def parse_auction
    m = @string.match(/\|\s*sv\s*\|(?<auction>(?:.|\n)*?)\s*\|\s*pc\s*\|/)
    raise ParseError.new 'Bad auction' if m.nil?
    
    #p m['auction']
    self.explanation = ''
    self.auction = m['auction'][5..-1].split(/\s*\|\s*mb\s*\|\s*/).map do |bid|
      bid.gsub(/^(?<bid>[^!|]+)!?(?:\|an\|(?<an>.*))?/) do |match|
        self.explanation << "#{$~['bid']}: #{$~['an']}\n" if $~['an']
        $~['bid']
      end.gsub('p', '-').gsub('d', 'X').gsub('r', 'XX')
    end.join(' ')
  end

  def parse_comments
    self.comments = ''
    @string.gsub!(/\|\s*nt\s*\|\s*(?<comment>.*?)\s*\|pg\|/) do |m|
      #p $~['comment']
      self.comments << $~['comment'] + "\n"
      ''
    end
  end

  def parse(string, players, vugraph)
    @string = string

    begin
      parse_comments
      parse_room_number players
      parse_hands
      parse_auction
      save
      p @players
      self.seats = @players.map do |player|
        #p player
        self.players << player
        #p player
        #player.name
        'anything'
      end.join(' ')
      self.vugraph = vugraph
      save
    rescue ParseError => error
      puts error.message
      p @string
    end
  end

  def self.find_auction sequence
    onepass = '- ' + sequence
    twopass = '- ' + onepass
    threepass = '- ' + twopass
    Board.all.find_all do |board|
      players = board.players.split(',')
      if (players[0] =~ /nunes/i || players[0] =~ /fantoni/i) # sit ns
        shift = board.number % 2 == 0 # shift when even board
      else
        shift = board.number % 2 == 1 # else shift at odd board
      end

      if shift
        board.auction.starts_with?(onepass) || board.auction.starts_with?(threepass)
      else
        board.auction.starts_with?(sequence) || board.auction.starts_with?(twopass)
      end
    end
  end
end
