module MainHelper
  def dealer(number)
    case number % 4
    when 1; 'North'
    when 2; 'East'
    when 3; 'South'
    else;   'West'
    end
  end

  def vul(number)
    case (number / 4 + number) % 4
    when 1; 'None'
    when 2; 'N/S'
    when 3; 'E/W'
    else;   'All'
    end
  end

  def print_hand(hand)
    h = hand.split(/S|H|D|C/)
    "#{spades} #{h[1]}<br>#{hearts} #{h[2]}<br>#{diamonds} #{h[3]}<br>#{clubs} #{h[4]}".html_safe
  end

  def spades
    '&spades;'.html_safe
  end

  def hearts
    '<font color="FF0000">&hearts;</font>'.html_safe
  end

  def diamonds
    '<font color="FF0000">&diam;</font>'.html_safe
  end

  def clubs
    '&clubs;'.html_safe
  end

  def to_figure bid
    bid.gsub(/S/, spades).gsub(/H/, hearts).gsub(/D/, diamonds).gsub(/C/, clubs).html_safe
  end
end
