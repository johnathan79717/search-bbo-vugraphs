class Vugraph < ActiveRecord::Base
  attr_accessible :lin_file, :event, :segment
  has_many :boards, dependent: :destroy

  def self.download!(id)
    if id.class == Range
      id.each do |x|
        download!(x)
      end
      return
    end
    if exists? id
      v = find(id)
      v.destroy
    end

    download(id)
  end


  def self.download(id)
    if id.class == Range
      id.each do |x|
        download(x)
      end
      return
    end
    if !exists? id
      url = URI.parse("http://www.bridgebase.com/tools/vugraph_linfetch.php?id=#{id}")
      req = Net::HTTP::Get.new(url.to_s)
      res = Net::HTTP.start(url.host, url.port) do |http|
        http.request(req)
      end

      if res.body == "Fetch failed (2)"
        puts "#{id}.lin does not exists"
      else
        vugraph = new do |v|
          v.id = id
          v.lin_file = res.body.gsub("\r\n", '')
          v.parse
        end
      end
    end
  end

  def parse_event_segment
    m = lin_file.match(/vg\|\s*(?<event>.*?)\s*,\s*(?<segment>.*?)\s*,/)
    if m.nil?
      p lin_file
      raise ParseError.new 'Bad event and segment'
    end

    self.event = m['event']
    self.segment = m['segment']
  end

  def parse_players
    m = lin_file.match(/p[nw]\|(?<players>(?:.|\r\n)*?)\|/)
    if m.nil?
      p lin_file
      raise ParseError.new 'Bad players'
    end
    @players = m['players'].gsub('\r\n', '').split(/\s*,\s*/)
  end

  def parse_board
    @@unsaved_boards = []
    error_count = 0
    lin_file.scan(/\|(?<board_string>qx(?:\s|.)*?)(?=\Z|\s*\|\s*qx\s*\|)/) do |match|
      board_string = $~['board_string']
      if board_string !~ /mb/
        error_count += 1
        next
      end
      Board.new do |b|
        begin
          b.parse(board_string, @players, self)
        rescue ParseError => error
          error_count += 1
          if error.message =~ /\ANot enough player/
            puts error.message
          else
            puts "Error: #{id}.lin"
            puts error.message + "\n" + board_string.inspect
            if error.message !~ /ABad auction/
              Blacklist.add(id)
            end
          end
        else
          @@unsaved_boards << b
        end
      end
    end
    if @@unsaved_boards.empty?
      p lin_file
      puts 'No boards found'
      #raise ParseError.new 'No boards found'
    end
    if lin_file.scan(/\|qx\|/).size != @@unsaved_boards.size + error_count
      raise ParseError.new 'Some boards are not parsed'
    end
  end

  def parse
    begin
      parse_event_segment
      parse_players
      parse_board
    rescue ParseError => error
      puts "Error: #{id}.lin"
      Blacklist.add(id)
      puts error.message
    else
      puts "#{id} has #{@@unsaved_boards.size} boards"
      begin
        save
        @@unsaved_boards.each do |b|
          b.save
        end
      rescue ActiveRecord::StatementInvalid => e
        puts e.message.split("\n")[0]
        delete
        @@unsaved_boards.each do |b|
          b.delete
        end
      end
    end
  end
      
end
