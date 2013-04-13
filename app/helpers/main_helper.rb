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
    return "S #{h[0]}<br>H #{h[1]}<br>D #{h[2]}<br>C#{h[3]}".html_safe
  end
end
