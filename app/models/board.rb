require 'net/http'

class Board < ActiveRecord::Base
  attr_accessible :number, :players, :hands, :auction, :explanation, :event, :link

  def self.update
    url = "http://www.bridgebase.com/vugraph_archives/vugraph_archives.php?command=all"
    url = URI.parse(url)
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) do |http|
      http.request(req)
    end
    archive = res.body
    archive.scan(/<tr BGCOLOR=#E0.*?tr>/m) do |row|
      if row =~ /nunes/i && row =~ /fantoni/i
        row.match %r{<a href="(http://www.bridgebase.com/tools/vugraph_linfetch.php\?id=(\d+))">Download}m
        link = $1
        next if Board.find_by_link(link)
        self.download(link)
      end
    end
    return
  end

  def self.download(link)
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
    return
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

  def lin
    [10266,11583,15127,15990,19863,21812,24855,25735,3533,10302,11593,15138,15992,19870,21817,24861,25736,3535,10317,11614,15141,16008,19877,21820,24869,25743,3549,10319,11620,15177,16012,19894,21821,24874,25745,3552,10321,11624,15182,16031,19899,21822,24884,25840,3788,10596,11628,15186,16035,1994, 21823,24888,25843,3793,10781,12130,15195,16120,19979,22026,24903,25892,3796,10790,12133,15197,1613, 1998, 22028,24912,25897,3797,10813,12134,15203,1628, 19982,22054,24917,25918,3798,10836,12139,15206,16606,22057,24924,25923,3867,10846,12147,15209,16627,2001, 22062,24937,26043,3881,10862,12173,15216,16629,20028,22326,24943,26057,3883,10868,12180,15217,16632,2005, 22950,24947,26066,3903,10869,12189,15220,17068,20053,22958,24960,26070,3911,10946,12616,15223,17073,20058,22973,24964,26074,3915,10949,12618,15228,1748, 2006, 22992,24971,26076,3929,10970,1262, 15270,1751, 20061,23061,25214,26080,3931,10972,12621,15352,1752, 20110,23096,25220,26090,3937,10985,1263, 15361,17569,2013, 23100,25225,26092,3967,11005,1264, 15371,17574,20138,23102,25235,26260,3971,11009,12648,15373,17580,20140,23303,25236,26360,3996,11017,12649,15379,1759, 20155,23307,25240,26375,4012,11023,1267, 15383,1760, 20161,23308,25255,26465,4019,11051,12670,15386,17605,20164,23740,25259,26840,4033,11056,12671,15396,1761, 20172,23776,25263,26869,4257,11067,12673,15476,17610,2019, 23811,25268,26874,4258,11072,12678,15487,1762, 20244,23827,25271,26876,4259,11083,1269, 15529,1763, 20252,23834,25300,26893,4262,11086,1270, 15540,1767, 2033, 23876,25317,26896,4263,11100,13123,15542,1768, 2039, 23923,25391,27063,4264,11122,13129,15563,18365,2041, 23941,25394,27068,4265,11126,13136,15578,1879, 20431,23952,25407,27074,4266,11142,13571,15583,1883, 20432,23965,25410,27098,4267,11151,13592,15589,1885, 20433,23977,25575,27100,4656,11164,13606,15595,1886, 20448,23987,25580,27105,9069,11189,13632,15597,18873,20450,24232,25587,27106,9074,11212,13669,15599,18908,20453,24279,25591,27348,9077,11224,13979,15602,18918,2069, 24287,25595,2976, 9080,11228,13980,15751,18923,2078, 24291,25600,2977, 9082,11230,13985,15760,18936,2079, 24294,25603,3277, 9084,11236,13993,15780,19417,2085, 24295,25608,3283, 9318,11240,14017,15785,19418,20850,24301,25612,3292, 9322,11266,14028,15891,19434,20917,24304,25614,3486, 9325,11274,14865,15901,19438,20918,24306,25619,3487, 9490,11275,14869,15904,19440,20928,24307,25711,3496, 9491,11277,14872,15926,19445,20931,24309,25713,3500, 9509,11279,14875,15942,19447,21200,24704,25725,3507, 9517,11280,14883,15953,19448,21201,24759,25728,3508, 11286,14884,15956,19842,21203,24800,25730,3513, 11527,14887,15976,19843,21313,24811,25731,3514, 11535,14892,15981,19848,21315,24812,25732,3515, 11565,14893,15987,19851,21785,24821,25733,3519, 11577,14894,15989,19862,21796,24848,25734,3522]
  end
end