require 'net/http'

class Lin < ActiveRecord::Base
  attr_accessible :body, :filename

  def self.download(linname)
    url = URI.parse("http://www.bridgebase.com/tools/vugraph_linfetch.php?id=#{linname}")
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) do |http|
      http.request(req)
    end

    Lin.create(:body => res.body, :filename => linname)
  end

  def self.find_board(sequence)
    self.all.each do |file|
      lin = file.body
      unless lin =~ /vg\|\s*(.*?)\s*,\s*(.*?)\s*,/
        raise 'Event name not matched in ' + filename
      end
      event = $1 + ', ' + $2
      unless lin =~ /pn\|(.*?)\|/
        raise 'Player names not matched in ' + event
      end
      players = $1.split ','
      lin.gsub! /nt\|.*?\|/, ''
      lin.gsub! 'pg||', ''
      lin.gsub! "\r\n", ''
      n, f = /nunes/i, /fantoni/i
      room, direction =
        if players[0] =~ n && players[2] =~ f || players[2] =~ n && players[0] =~ f
          [:o, :ns]
        elsif players[1] =~ n && players[3] =~ f || players[3] =~ n && players[1] =~ f
          [:o, :ew]
        elsif players[6] =~ n && players[4] =~ f || players[4] =~ n && players[6] =~ f
          [:c, :ns]
        elsif players[7] =~ n && players[5] =~ f || players[5] =~ n && players[7] =~ f
          [:c, :ew]
        else
          puts "Warning: Can\'t find Fantunes"
        end
      next unless room
      total = lin.scan(/\|qx\|#{room}(\d+)/).flatten
      parsed = []
      # p lin
      regex = case room
                when :o; /\|qx\|o(\d+)\|(st\|\|)?md\|(.*?)\|sv\|.\|(((mb|an)\|[^|]*\|)+)/
                when :c; /\|qx\|c(\d+)\|(st\|\|)?md\|(.*?)\|sv\|.\|(((mb|an)\|[^|]*\|)+)/
              end
      lin.scan /\|qx\|#{room}(\d+)\|(st\|\|)?md\|(.*?)\|sv\|.\|(((mb|an)\|[^|]*\|)+)/ do |board, _, hands, alerted_auction|
        parsed << board
        board = board.to_i
        if hands.size < 68
          # puts "Warning: no hands in #{filename}, board #{board}"
          next
        end
        hands = hands.split(',')
        hands[0] = hands[0][1, 17]
        alerted_auction = alerted_auction[3...-1].split('|mb|')
        explanation = ''
        auction = alerted_auction.map do |bid|
          bid.gsub(/^([^!|]+)!?(\|an\|(.*))?/) do |match|
            explanation << "#{$1}: #{$3}\n" if $3
            $1
          end.gsub('p', '-').gsub('d', 'X').gsub('r', 'XX')
        end
        # p alerted_auction
        # p auction
        offset = case direction
                 when :ns; 1 - board % 2
                 when :ew; board % 2
                 end
        sequence = ['-', *sequence] if offset == 1
        find_hand event, board, hands, auction, offset, sequence, explanation
        find_hand event, board, hands, auction, offset, ['-', '-', *sequence], explanation
      end
      puts "Warning: No boards found in #{filename}" if parsed.empty?
      if parsed != total
        # p lin
        puts "Warning: #{filename}: board #{total - parsed} not parsed"
      end
    end
  end

  def self.find_hand event, board, hands, auction, offset, sequence, explanation
    # p board, auction, offset, sequence
    if sequence.size <= auction.size and 
                        auction[0, sequence.size] == sequence
      puts "#{event}, Board #{board}"
      if ARGV[0] == '-d'
        opener = hands[(board + 2 + offset) % 4].split(/S|H|D|C/)
        responder = hands[(board + 4 + offset) % 4].split(/S|H|D|C/)      
      else
        opener = hands[(board + 1 + offset) % 4].split(/S|H|D|C/)
        responder = hands[(board + 3 + offset) % 4].split(/S|H|D|C/)
      end
      opener << '' if opener.size == 4
      responder << '' if responder.size == 4
      puts "#{' ' * 20 if ARGV[0] == '-d'}S #{opener[1].ljust(37)} S #{responder[1]}"
      puts "#{' ' * 20 if ARGV[0] == '-d'}H #{opener[2].ljust(37)} H #{responder[2]}"
      puts "#{' ' * 20 if ARGV[0] == '-d'}D #{opener[3].ljust(37)} D #{responder[3]}"
      puts "#{' ' * 20 if ARGV[0] == '-d'}C #{opener[4].ljust(37)} C #{responder[4]}"
      puts
      (offset...auction.size).step(2) do |i|
        if i + 1 < auction.size
          space = (40 - auction[i].size - auction[i+1].size) / 2
          auction[i] = auction[i].ljust(20)
          auction[i] << "#{auction[i+1]}"
        end
        if (i-offset) % 4 == 0
          print auction[i].ljust(40)
        else
          puts auction[i]
        end
      end
      # p alerted_auction
      puts
      puts '', explanation unless explanation.empty?
      puts
    end
  end

end
