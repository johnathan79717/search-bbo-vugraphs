require 'net/http'

class Board < ActiveRecord::Base
  attr_accessible :number, :players, :hands, :auction, :explanation, :event, :link

  def self.download(linname)
    link = "http://www.bridgebase.com/tools/vugraph_linfetch.php?id=#{linname}"
    url = URI.parse(link)
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) do |http|
      http.request(req)
    end

    lin = res.body
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
    return unless room
    if room == :o
      players = players[0..3].join(',')
    else
      players = players[4..7].join(',')
    end

    lin.scan /\|qx\|#{room}(\d+)\|(st\|\|)?md\|(.*?)\|sv\|.\|(((mb|an)\|[^|]*\|)+)/ do |board, _, hands, alerted_auction|
      board = board.to_i
      if hands.size < 68
        # puts "Warning: no hands in #{filename}, board #{board}"
        return
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
                   :link        => link,
                   :players     => players,
                   :hands       => hands, 
                   :auction     => auction,
                   :explanation => explanation, 
                   :event       => event)
    end
  end

  def self.find_auction sequence
    onepass = '-' + sequence
    twopass = '-' + onepass
    threepass = '-' + twopass
    Board.all.find_all do |board|
      players = board.players.split(',')
      offset = if players[0] =~ /nunes/i || players[0] =~ /fantoni/i
                  (board.number - 1) % 2
                else
                  (board.number) % 2
      if offset
        board.auction.starts_with?(onepass) || board.auction.starts_with?(threepass)
      else
        board.auction.starts_with?(sequence) || board.auction.starts_with?(twopass)
      end
    end
  end
end