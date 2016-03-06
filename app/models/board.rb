require 'net/http'

class ParseError < StandardError
  attr_accessor :message
  def initialize(msg)
    self.message = msg
  end
end

class Board < ActiveRecord::Base
  attr_accessible :number, :hands, :auction, :explanation, :comments, :seats
  belongs_to :vugraph
  has_many :players_boards, class_name: 'PlayersBoard', dependent: :destroy
  has_many :players, class_name: 'Player', through: :players_boards

  def parse_room_number players
    m = @string.match(/\Aqx\|(?<room>o|c)(?<number>\d+)/)
    if m.nil?
      p @string
      raise ParseError.new 'Bad room or number'
    end

    self.room = m['room']
    if m['room'] == 'o'
      raise ParseError.new 'Not enough player ' + players.inspect if players.size < 4
      @players = players[0..3]
    else
      raise ParseError.new 'Not enough player ' + players.inspect if players.size < 8
      @players = players[4..7]
    end

    self.number = m['number']
  end

  def parse_hands
    m = @string.match(/(?:\d|\|)md\|(?<hands>.*?)\|/)
    if m.nil?
      p @string
      raise ParseError.new 'Bad hands'
    end
    hands = m['hands'].split(',')
    if hands.size == 4
      self.hands = m['hands']
    elsif hands.size == 3
      fourth = ['AKQJT98765432'] * 4
      hands.each do |h|
        h.split(/[SHDC]/)[1..4].each_with_index do |v, i|
          fourth[i] = fourth[i].delete(v)
        end
      end
      self.hands = m['hands'] + ',S'+fourth[0]+'H'+fourth[1]+'D'+fourth[2]+'C'+fourth[3]
    else
      raise ParseError.new 'Bad hands' if m.nil?
    end
  end
    
  def parse_auction
    m = @string.match(/\|mb\|(?<auction>.*?(?:\|mb\|p!?(?:\|an\|[^|]*)?){3})/i)
    raise ParseError.new 'Bad auction' if m.nil?
    
    self.explanation = ''
    self.auction = m['auction'].split(/\|+mb\|+/i)
    if auction.size == 1
      self.auction = auction[0].scan(/[PDR]|[1-7](?:[CDHS]|NT?)/i)
    end
    self.auction.map! do |bid|
      next if bid == '-'
      if bid !~ /\A!?(?<bid>(?:[PDRX]|[1-7](?:[CDHS]|NT?)))(?:[^|]*)(?:\|?AN\|(?<an>.*))?\Z/i
        p m['auction']
        p self.auction
        raise ParseError.new "Bad bid: " + bid.inspect
      else
        bid = $~['bid'].upcase
        an = $~['an']
        self.explanation << "#{bid}: #{an}\n" if an
      end
      bid = '-' if bid == 'P'
      bid = 'X' if bid == 'D'
      bid = 'XX' if bid == 'R'
      if bid !~ /\A(?:-|X|XX|[1-7](?:[CDHS]|NT?))\Z/
        raise ParseError.new "Bad bid: " + bid.inspect
      end
      bid
    end
    if auction.size < 4
      raise ParseError.new 'Auction too short'
    end
    self.auction = auction.join(' ')
    if self.auction !~ /-\s+-\s+-\s*\Z/
      p self.auction
      raise ParseError.new 'Auctions must end with three passes'
    end
  end

  def parse_comments
    self.comments = ''
    @string.gsub!(/\|nt\|(?<comment>.*?)(?:\|pg)?\|/) do |m|
      if $~['comment'].size > 0
        self.comments << $~['comment'] + "\n"
      end
      ''
    end
  end

  def parse(string, players, vugraph)
    @string = string.gsub("\r\n", '').gsub(/pa\|\d+\|/, '')

    parse_comments

    @string.gsub!('|pg|', '')
    parse_room_number players
    parse_hands
    parse_auction
    self.seats = @players.join(',')
    @players.each do |name|
      name.force_encoding('utf-8')
      self.players << Player.find_or_create_by_name(name.upcase)
    end
    self.vugraph = vugraph
  end

  def self.find_auction sequence
    Board.all.find_all do |board|
      if board.auction.nil?
        p board
      else
        board.auction.match(/\A(- ){,3}#{sequence}/)
      end
    end
  end
end
