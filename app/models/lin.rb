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

  def self.find_board(argv)
    ret = ""
    self.all.each do |file|
      lin = file.body
      lin =~ /vg\|\s*(.*?)\s*,\s*(.*?)\s*,/
      event = $1 + ', ' + $2
      lin =~ /pn\|(.*?)\|/
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
        elsif players[7] =~ n && players[5] =~ f ||players[5] =~ n && players[7] =~ f
          [:c, :ew]
        else
          puts "Warning: Can\'t find Fantunes"
        end
      next unless room
      if room == :o
        players = players[0..3].join(',')
      else
        players = players[4..7].join(',')
      end

      lin.scan /\|qx\|#{room}(\d+)\|(st\|\|)?md\|(.*?)\|sv\|.\|(((mb|an)\|[^|]*\|)+)/ do |board, _, hands, alerted_auction|
        board = board.to_i
        if hands.size < 68
          # puts "Warning: no hands in #{filename}, board #{board}"
          next
        end
        hands = hands[1..-1]
        alerted_auction = alerted_auction[3...-1].split('|mb|')
        explanation = ''
        auction = alerted_auction.map do |bid|
          bid.gsub(/^([^!|]+)!?(\|an\|(.*))?/) do |match|
            explanation << "#{$1}: #{$3}\n" if $3
            $1
          end.gsub('p', '-').gsub('d', 'X').gsub('r', 'XX')
        end.join(' ')
        Board.create(:number      => board,
                     :players     => players,
                     :hands       => hands, 
                     :auction     => auction,
                     :explanation => explanation, 
                     :event       => event)
        # p alerted_auction
        # p auction
        # offset = case direction
        #          when :ns; 1 - board % 2
        #          when :ew; board % 2
        #          end
        # sequence = argv
        # sequence = ['-', *sequence] if offset == 1
        # p "offset = #{offset}"
        # p "sequence = #{sequence}"
        # ret << find_hand(event, board, hands, auction.dup, offset, sequence, explanation)
        # ret << find_hand(event, board, hands, auction.dup, offset, ['-', '-', *sequence], explanation)
      end
    end
    # return ret
  end

  def self.find_hand event, board, hands, auction, offset, sequence, explanation
    # p board, auction, offset, sequence
    ret = ""
    if sequence.size <= auction.size and 
                        auction[0, sequence.size] == sequence
      ret << "#{event}, Board #{board}<br>"
      opener = hands[(board + 1 + offset) % 4].split(/S|H|D|C/)
      responder = hands[(board + 3 + offset) % 4].split(/S|H|D|C/)

      puts "S #{opener[1].ljust(37)} S #{responder[1]}"
      puts "H #{opener[2].ljust(37)} H #{responder[2]}"
      puts "D #{opener[3].ljust(37)} D #{responder[3]}"
      puts "C #{opener[4].ljust(37)} C #{responder[4]}"
      ret << "<br>"
      (offset...auction.size).step(2) do |i|
        if i + 1 < auction.size
          space = (40 - auction[i].size - auction[i+1].size) / 2
          auction[i] = auction[i].ljust(20)
          auction[i] << "#{auction[i+1]}"
        end
        if (i-offset) % 4 == 0
          ret << auction[i].ljust(40)
        else
          ret << auction[i] << "<br>"
        end
      end
      # p alerted_auction
      ret << "<br>"
      ret << explanation << "<br>" unless explanation.empty?
      ret << "<br>"
    end
    return ret
  end
end
