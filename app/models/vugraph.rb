class Vugraph < ActiveRecord::Base
  attr_accessible :lin_file, :event, :segment
  has_many :boards

  def self.download(id)
    if !exists? id
      url = URI.parse("http://www.bridgebase.com/tools/vugraph_linfetch.php?id=#{id}")
      req = Net::HTTP::Get.new(url.to_s)
      res = Net::HTTP.start(url.host, url.port) do |http|
        http.request(req)
      end

      if res.body == "Fetch failed (2)"
        print 'File not exists'
      else
        #p res.body
        vugraph = new do |v|
          v.id = id
          v.parse(res.body)
          v.save
        end
      end
    end
  end

  def parse_event_segment
    m = lin_file.match(/vg\|\s*(?<event>.*?)\s*,\s*(?<segment>.*?)\s*,/)
    raise ParseError.new 'Bad event and segment' if m.nil?
    self.event = m['event']
    self.segment = m['segment']
  end

  def parse_players
    m = lin_file.match(/pn\|(?<players>.*?)\|/)
    raise ParseError.new 'Bad players' if m.nil?
    @players = m['players'].split(',').map do |name|
      name.upcase!
      Player.find_by_name(name) || Player.create(name: name)
    end
  end

  def parse_board
    lin_file.scan(/(?<board_string>^qx(?:\s|.)*?)(?=\Z|\s*\|\s*qx\s*\|)/) do |match|
      board_string = $~['board_string']
      board = Board.create
      board.parse(board_string, @players, self)
    end
  end

  def parse(lin_file)
    self.lin_file = lin_file

    begin
      parse_event_segment
      parse_players
      parse_board
    rescue ParseError => error
      print error.message + ': ' + id.to_s
    end
  end
      
end
